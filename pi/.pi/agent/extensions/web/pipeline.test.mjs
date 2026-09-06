import '../test-support/loader.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseHTML } from 'linkedom';
import { readFile, rm } from 'node:fs/promises';
const { default: web, cleanFallback, extractFetchedPage, formatFetchedPage, fetchPublicPage } = await import('./index.ts');

function fixture(source, type = 'text/html') {
  return { requestedUrl: 'https://example.com/old', finalUrl: 'https://example.com/article',
    response: new Response(null, { headers: { 'content-type': type } }), body: new TextEncoder().encode(source) };
}

test('fallback strips scripts, styles, navigation and hidden content', () => {
  const result = cleanFallback('<html><body><nav>navigation noise</nav><main><p>Useful words.</p><script>secretScript()</script><style>.noise{}</style><div hidden>hidden noise</div><aside>aside noise</aside></main><footer>footer noise</footer></body></html>', parseHTML);
  assert.equal(result, 'Useful words.');
});

test('real Defuddle extraction preserves article text and links', async () => {
  const page = await extractFetchedPage(fixture('<html><head><title>Test article</title></head><body><main><h1>Test article</h1><p>This is a sufficiently long article about browser testing, including real extraction of useful information and readable links.</p><p>Read the <a href="https://example.com/docs">documentation</a> for more information.</p></main></body></html>'));
  assert.match(page.content, /sufficiently long article/);
  assert.match(page.content, /\[documentation\]\(https:\/\/example.com\/docs\)/);
  assert.equal(page.title, 'Test article');
});

test('model-visible metadata includes resolved source and labels fallback', () => {
  const text = formatFetchedPage({ requestedUrl:'https://example.com/old', finalUrl:'https://example.com/new', title:'Article', author:'Writer', published:'2026-09-05', fallback:true, content:'Body' });
  for (const value of ['Title: Article', 'Source: https://example.com/new', 'Requested: https://example.com/old', 'Author: Writer', 'Published: 2026-09-05', 'plain-text fallback', 'Body']) assert.ok(text.includes(value));
});

test('JSON is formatted, binary and empty responses fail, aborted extraction stops', async () => {
  assert.equal((await extractFetchedPage(fixture('{"ok":true}', 'application/json'))).content, '{\n  "ok": true\n}');
  await assert.rejects(extractFetchedPage(fixture('binary', 'application/pdf')), /Unsupported/);
  await assert.rejects(extractFetchedPage(fixture('', 'text/plain')), /No readable/);
  await assert.rejects(extractFetchedPage(fixture('<p>test</p>'), AbortSignal.abort(new Error('cancelled'))), /cancelled/);
});

test('fetch pipeline revalidates redirects and preserves final URL', async () => {
  const hosts = [], requests = [];
  const dependencies = {
    resolve: async host => { hosts.push(host); return [{address:'8.8.8.8',family:4}]; },
    fetch: async (url, addresses, options) => {
      requests.push(url.href);
      assert.deepEqual(addresses, [{address:'8.8.8.8',family:4}]);
      assert.ok(options.signal);
      return requests.length === 1 ? new Response(null, {status:302,headers:{location:'https://other.example/article'}}) : new Response('article');
    },
  };
  const result = await fetchPublicPage('https://example.com/old', undefined, dependencies);
  assert.deepEqual(hosts, ['example.com','other.example']);
  assert.equal(result.finalUrl, 'https://other.example/article');
  assert.equal(new TextDecoder().decode(result.body), 'article');
});

test('private redirects are blocked before the second request', async () => {
  let requests = 0;
  await assert.rejects(fetchPublicPage('https://example.com/', undefined, {
    resolve: async () => [{address:'8.8.8.8',family:4}],
    fetch: async () => { requests++; return new Response(null,{status:302,headers:{location:'http://127.0.0.1/'}}); },
  }), /non-public/);
  assert.equal(requests, 1);
});

test('redirect loops and missing locations fail predictably', async () => {
  for (const location of [undefined, '/loop']) {
    let count = 0;
    await assert.rejects(fetchPublicPage('https://example.com/', undefined, {
      resolve: async () => [{address:'8.8.8.8',family:4}],
      fetch: async () => { count++; return new Response(null,{status:302,headers:location ? {location} : {}}); },
    }), location ? /Too many redirects/ : /Location header/);
    assert.equal(count, location ? 6 : 1);
  }
});

test('search truncation reports and saves complete output when Pi truncates', async () => {
  const tools = new Map(); web({registerTool: tool => tools.set(tool.name,tool)});
  const originalFetch = globalThis.fetch, originalKey = process.env.BRAVE_SEARCH_API_KEY;
  let path;
  // Simulate Pi's truncation boundary; this tests our notice/file wiring, not Pi's implementation.
  globalThis.__piTestTruncateHead = (content, options) => {
    assert.equal(options.maxBytes,51200);
    return {content:content.slice(0,10),truncated:true,truncatedBy:'bytes',outputLines:1,totalLines:3};
  };
  process.env.BRAVE_SEARCH_API_KEY = 'test';
  globalThis.fetch = async () => new Response(JSON.stringify({web:{results:[{title:'A long search result',url:'https://example.com/',description:'Complete description retained in file'}]}}));
  try {
    const result = await tools.get('web_search').execute('truncated',{query:'long'});
    path = result.details.fullOutputPath;
    assert.ok(path);
    assert.match(result.content[0].text,/Full output:/);
    assert.match(await readFile(path,'utf8'),/Complete description retained in file/);
  } finally {
    delete globalThis.__piTestTruncateHead;
    globalThis.fetch = originalFetch;
    if (originalKey === undefined) delete process.env.BRAVE_SEARCH_API_KEY; else process.env.BRAVE_SEARCH_API_KEY = originalKey;
    if (path) await rm(path);
  }
});

test('Brave parsing, freshness, deduplication, cache and errors through registered tool', async () => {
  const originalFetch = globalThis.fetch, originalKey = process.env.BRAVE_SEARCH_API_KEY;
  const tools = new Map();
  web({registerTool: tool => tools.set(tool.name, tool)});
  const search = tools.get('web_search').execute;
  let calls = 0;
  process.env.BRAVE_SEARCH_API_KEY = 'test-key';
  globalThis.fetch = async url => {
    calls++;
    assert.equal(url.searchParams.get('freshness'), 'pw');
    return new Response(JSON.stringify({web:{results:[
      {title:'<b>Example</b>',url:'https://example.com/',description:'A &amp; B',age:'2 days ago'},
      {title:'Duplicate',url:'https://example.com/'},
      {title:'Invalid',url:'file:///etc/passwd'},
      {title:'Second',url:'https://example.org/'},
    ]}}));
  };
  try {
    const first = await search('1',{query:'test',freshness:'week',limit:2});
    assert.equal(first.details.resultCount,2);
    assert.match(first.content[0].text,/A & B/);
    assert.doesNotMatch(first.content[0].text,/Duplicate|Invalid|<b>/);
    assert.equal((await search('2',{query:'test',freshness:'week',limit:2})).details.cached,true);
    assert.equal(calls,1);
    await assert.rejects(search('3',{query:'test',freshness:'week',limit:2},AbortSignal.abort(new Error('cancelled'))),/cancelled/);
    globalThis.fetch = async () => new Response(null,{status:429});
    await assert.rejects(search('4',{query:'uncached'}),/429/);
    delete process.env.BRAVE_SEARCH_API_KEY;
    await assert.rejects(search('5',{query:'no key'}),/BRAVE_SEARCH_API_KEY/);
  } finally {
    globalThis.fetch = originalFetch;
    if (originalKey === undefined) delete process.env.BRAVE_SEARCH_API_KEY; else process.env.BRAVE_SEARCH_API_KEY = originalKey;
  }
});

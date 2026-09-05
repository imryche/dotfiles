import '../test-support/loader.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { randomUUID } from 'node:crypto';
import { parseHTML } from 'linkedom';
const { default: browserExtension, pageSnapshotRuntime, executionExpression, CdpClient } = await import('./index.ts');

function page(html) {
  const { window } = parseHTML(`<html><body>${html}</body></html>`);
  window.Element.prototype.getClientRects = () => [{}];
  const context = vm.createContext({
    document: window.document, Element: window.Element, Node: window.Node,
    MutationObserver: window.MutationObserver,
    getComputedStyle: () => ({ display: 'block', visibility: 'visible' }),
    location: { href: 'https://example.com/' }, setTimeout, clearTimeout, AbortController,
  });
  return {
    context,
    snapshot: selector => vm.runInContext(`(${pageSnapshotRuntime.toString()})(${JSON.stringify(randomUUID())}, ${JSON.stringify(selector) ?? 'undefined'})`, context),
    execute: code => vm.runInContext(executionExpression(code), context),
  };
}

test('snapshot preserves leaf list and table text without duplicating headings', () => {
  const p = page('<h1>Pricing</h1><ul><li>Important detail</li></ul><table><tr><td>$29</td></tr></table>');
  const { text } = p.snapshot();
  assert.match(text, /Important detail/);
  assert.match(text, /\$29/);
  assert.equal(text.match(/Pricing/g).length, 1);
});

test('refs cannot be reused across snapshots or replaced documents', async () => {
  const p = page('<button>First</button>');
  const first = p.snapshot().text.match(/ref=([^\]]+)/)[1];
  assert.equal(await p.execute(`return ref(${JSON.stringify(first)}).textContent`), 'First');
  p.context.document.body.innerHTML = '<button>Second</button>';
  p.snapshot();
  await assert.rejects(p.execute(`return ref(${JSON.stringify(first)})`), /Stale or unknown ref/);
  const other = page('<button>Other document</button>');
  other.snapshot();
  await assert.rejects(other.execute(`return ref(${JSON.stringify(first)})`), /Stale or unknown ref/);
});

test('scoped snapshots include only the requested subtree and replace all old refs', async () => {
  const p = page('<nav><button>Outside</button></nav><section id="faq"><h2>FAQs</h2><button>Question</button></section><footer>Footer</footer>');
  const full = p.snapshot();
  const oldRefs = [...full.text.matchAll(/ref=([^\]]+)/g)].map(match => match[1]);
  const scoped = p.snapshot('#faq');
  assert.match(scoped.text, /FAQs/);
  assert.match(scoped.text, /Question/);
  assert.doesNotMatch(scoped.text, /Outside|Footer/);
  assert.equal(scoped.refCount, 1);
  assert.ok(scoped.nodeCount < full.nodeCount);
  for (const id of oldRefs) await assert.rejects(p.execute(`return ref(${JSON.stringify(id)})`), /Stale/);
  const current = scoped.text.match(/ref=([^\]]+)/)[1];
  assert.equal(await p.execute(`return ref(${JSON.stringify(current)}).textContent`), 'Question');
});

test('missing and invalid scopes fail without replacing valid refs', async () => {
  const p = page('<button>Keep</button>');
  const id = p.snapshot().text.match(/ref=([^\]]+)/)[1];
  for (const selector of ['#missing', '[', '']) assert.throws(() => p.snapshot(selector));
  assert.equal(await p.execute(`return ref(${JSON.stringify(id)}).textContent`), 'Keep');
  await assert.rejects(p.execute('return snapshot({target: document.createElement("div")})'), /detached/);
});

test('execution snapshot accepts selectors, refs, elements, and whole-page scope', async () => {
  const p = page('<button id="outside">Outside</button><section id="faq"><button>Question</button></section>');
  for (const target of ['"#faq"', 'query("#faq")']) {
    const result = await p.execute(`return snapshot({target: ${target}})`);
    assert.equal(result.__piBrowserCommand, 'snapshot');
    assert.match(result.snapshot.text, /Question/);
    assert.doesNotMatch(result.snapshot.text, /Outside/);
  }
  const id = p.snapshot('#faq').text.match(/ref=([^\]]+)/)[1];
  const result = await p.execute(`return snapshot({target: ${JSON.stringify(id)}})`);
  assert.match(result.snapshot.text, /Question/);
  await assert.rejects(p.execute(`return ref(${JSON.stringify(id)})`), /Stale/);
  assert.match((await p.execute('return snapshot()')).snapshot.text, /Outside/);
});

test('multiple snapshots in one execution get distinct refs', async () => {
  const p = page('<button>Question</button>');
  const result = await p.execute('const first = snapshot(); const second = snapshot(); return {first, second};');
  const first = result.first.snapshot.text.match(/ref=([^\]]+)/)[1];
  const second = result.second.snapshot.text.match(/ref=([^\]]+)/)[1];
  assert.notEqual(first, second);
  await assert.rejects(p.execute(`return ref(${JSON.stringify(first)})`), /Stale/);
  assert.equal(await p.execute(`return ref(${JSON.stringify(second)}).textContent`), 'Question');
});

test('display:contents ancestors do not hide an otherwise visible scope', () => {
  const p = page('<main><section id="faq"><button>Question</button></section></main>');
  p.context.getComputedStyle = (element) => element.tagName === 'MAIN'
    ? { display: 'contents', visibility: 'visible' }
    : { display: 'block', visibility: 'visible' };
  p.context.Element.prototype.getClientRects = function getClientRects() {
    return this.tagName === 'MAIN' ? [] : [{}];
  };
  const scoped = p.snapshot('#faq');
  assert.match(scoped.text, /Question/);
  assert.equal(scoped.refCount, 1);
  assert.match(p.snapshot().text, /Question/);
});

test('scoped snapshots honor hidden ancestors', () => {
  const p = page('<section hidden><div id="hidden"><button>Secret</button></div></section>');
  assert.equal(p.snapshot('#hidden').refCount, 0);
  assert.doesNotMatch(p.snapshot('#hidden').text, /Secret/);
});

test('cancellation stops pending sleep and waitFor helpers', async () => {
  for (const code of ['await sleep(10000); return "late"', 'await waitFor(".missing", 10000)']) {
    const p = page('');
    const pending = p.execute(code);
    const rejected = assert.rejects(pending, /cancelled/);
    vm.runInContext('globalThis.__piBrowserCancel()', p.context);
    await rejected;
  }
});

test('event waiter rejection is handled even before the navigation promise settles', async () => {
  const socket = new EventTarget();
  const cdp = new CdpClient(socket);
  const waiter = cdp.waitForEvent('Page.domContentEventFired', 's', undefined, 5);
  await new Promise(resolve => setTimeout(resolve, 30));
  await assert.rejects(waiter.promise, /timed out/);
});

function fakeBrowser() {
  const tools = new Map();
  const handlers = new Map();
  const commands = new Map();
  browserExtension({
    registerTool: tool => tools.set(tool.name, tool),
    registerCommand: (name, command) => commands.set(name, command),
    on: (name, fn) => handlers.set(name, fn),
  });
  let targets = [{ targetId: 'A', title: 'A' }, { targetId: 'B', title: 'B' }];
  const sessions = new Map();
  const actions = [];
  let active = 0, maximum = 0;
  const cdp = {
    isClosed: false,
    listTargets: async () => { await new Promise(r => setTimeout(r, 2)); return targets; },
    attach: async id => { sessions.set(id, id); return id; },
    isolatedWorld: async id => id,
    send: async (method, params, session) => {
      if (method !== 'Runtime.evaluate') throw new Error(method);
      active++; maximum = Math.max(maximum, active);
      await new Promise(r => setTimeout(r, 5));
      active--;
      if (!params.expression.startsWith('(async () =>')) return { result: { value: { text: 'snapshot', refCount: 0, nodeCount: 0 } } };
      actions.push(session);
      return { result: { type: 'string', value: session } };
    },
  };
  return { tools, commands, handlers, cdp, actions, setTargets: value => { targets = value; }, max: () => maximum };
}

test('tab selection retains snapshot identities, rejects closed tabs, and serializes calls', async () => {
  const original = CdpClient.connect;
  const b = fakeBrowser();
  CdpClient.connect = async () => b.cdp;
  try {
    const snapshot = b.tools.get('browser_snapshot').execute;
    const execute = b.tools.get('browser_execute').execute;
    await snapshot('1', {});
    b.setTargets([{ targetId: 'B' }, { targetId: 'A' }]);
    await execute('2', { tab: 0, code: 'return 1' });
    assert.equal(b.actions.at(-1), 'A');
    await Promise.all([execute('3', { code: 'return 1' }), execute('4', { code: 'return 2' })]);
    assert.equal(b.max(), 1);
    b.setTargets([{ targetId: 'B' }]);
    await assert.rejects(execute('5', { tab: 0, code: 'return 1' }), /unavailable/);
    await snapshot('6', {}); // Recover and rebuild the index mapping.
    await execute('7', { tab: 0, code: 'return 1' });
    assert.equal(b.actions.at(-1), 'B');
    const controller = new AbortController();
    controller.abort();
    await assert.rejects(execute('8', { code: 'return 1' }, controller.signal));
    await execute('9', { code: 'return 1' }); // An aborted call must not poison the queue.
  } finally {
    CdpClient.connect = original;
  }
});

test('/browser status is connect-only; open focuses a tab; shutdown only disconnects', async () => {
  const original = CdpClient.connect;
  const b = fakeBrowser();
  const messages = [];
  const ctx = { hasUI: true, ui: { notify: text => messages.push(text) } };
  const command = b.commands.get('browser').handler;
  let attempts = 0, closed = 0;
  try {
    CdpClient.connect = async () => {
      attempts++;
      throw Object.assign(new Error('refused'), { code: 'ECONNREFUSED' });
    };
    await command('status', ctx);
    assert.equal(attempts, 1);
    assert.match(messages.at(-1), /not running/);
    b.cdp.close = () => { closed++; };
    const calls = [];
    b.cdp.send = async (method, params) => { calls.push({ method, params }); return {}; };
    CdpClient.connect = async () => b.cdp;
    await command('open', ctx);
    assert.deepEqual(calls, [{ method: 'Target.activateTarget', params: { targetId: 'A' } }]);
    await command('status', ctx);
    assert.equal(closed, 0); // Status must not close the session's cached connection.
    await b.handlers.get('session_shutdown')();
    assert.equal(closed, 1);
    assert.equal(calls.some(call => call.method === 'Browser.close'), false);
  } finally {
    CdpClient.connect = original;
  }
});

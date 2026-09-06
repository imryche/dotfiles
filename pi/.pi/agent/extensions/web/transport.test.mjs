import { test } from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { gzipSync } from 'node:zlib';
import { requestPinned } from './transport.mjs';

test('transport connects to supplied IP without resolving hostname, preserves Host, handles gzip and redirects', async () => {
  const server = http.createServer((req, res) => {
    assert.match(req.headers.host, /^does-not-exist.invalid:/);
    if (req.url === '/redirect') { res.writeHead(302,{location:'/plain'}); res.end(); return; }
    if (req.url === '/gzip') { res.writeHead(200,{'content-encoding':'gzip'}); res.end(gzipSync('decoded body')); return; }
    res.end('plain body');
  });
  await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
  try {
    for (const path of ['/plain','/gzip','/redirect']) {
      const result = await requestPinned(new URL(`http://does-not-exist.invalid:${server.address().port}${path}`),[{address:'127.0.0.1',family:4}]);
      const body = await new Response(result.body).text();
      if (path === '/redirect') { assert.equal(result.status,302); assert.equal(result.headers.get('location'),'/plain'); }
      else assert.equal(body,path === '/gzip' ? 'decoded body' : 'plain body');
    }
    await assert.rejects(requestPinned(new URL('http://example.com'),[],{signal:AbortSignal.abort(new Error('cancelled'))}),/cancelled/);
  } finally { await new Promise(resolve => server.close(resolve)); }
});

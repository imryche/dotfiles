import '../test-support/loader.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';
const { parsePublicUrl, assertPublicAddress, publicAddresses, pinnedLookup, readBody } = await import('./index.ts');

test('public fetch rejects unsafe URLs and addresses', async () => {
  for (const url of ['file:///etc/passwd', 'http://user:pass@example.com', 'https://example.com:8443']) {
    assert.throws(() => parsePublicUrl(url));
  }
  for (const address of ['127.0.0.1', '10.0.0.1', '169.254.169.254', '::1', '::ffff:127.0.0.1', 'fc00::1']) {
    assert.throws(() => assertPublicAddress(address), /non-public/);
  }
  for (const url of ['http://localhost', 'http://x.localhost', 'http://printer.local', 'http://127.1']) {
    await assert.rejects(publicAddresses(parsePublicUrl(url)));
  }
  assert.doesNotThrow(() => assertPublicAddress('8.8.8.8'));
  assert.doesNotThrow(() => assertPublicAddress('2606:4700:4700::1111'));
});

test('all DNS answers must be public', async () => {
  const resolve = async () => [{ address: '8.8.8.8', family: 4 }, { address: '10.0.0.1', family: 4 }];
  await assert.rejects(publicAddresses(new URL('https://example.com'), resolve), /non-public/);
});

test('connection lookup uses validated addresses instead of resolving again', async () => {
  let calls = 0;
  const resolve = async () => [{ address: ++calls === 1 ? '8.8.8.8' : '127.0.0.1', family: 4 }];
  const addresses = await publicAddresses(new URL('https://example.com'), resolve);
  const lookup = pinnedLookup(addresses);
  const lookupOne = options => new Promise((resolve, reject) => {
    lookup('example.com', options, (error, address, family) => error ? reject(error) : resolve({ address, family }));
  });
  assert.deepEqual(await lookupOne({}), { address: '8.8.8.8', family: 4 });
  assert.deepEqual((await lookupOne({ all: true })).address, addresses);
  await assert.rejects(lookupOne({ family: 6 }), /No validated address/);
  assert.equal(calls, 1);
});

test('cancellation does not wait for stalled DNS', async () => {
  const controller = new AbortController();
  const pending = publicAddresses(new URL('https://example.com'), () => new Promise(() => {}), controller.signal);
  const rejected = assert.rejects(pending, /cancel DNS/);
  controller.abort(new Error('cancel DNS'));
  await rejected;
});

test('download limit applies to declared and streamed bodies', async () => {
  await assert.rejects(readBody(new Response('small', { headers: { 'content-length': '100' } }), 10), /too large/);
  let cancelled = false;
  const stream = new ReadableStream({
    pull(controller) { controller.enqueue(new Uint8Array(6)); },
    cancel() { cancelled = true; },
  });
  await assert.rejects(readBody(new Response(stream), 10), /download limit/);
  assert.equal(cancelled, true);
  assert.equal(new TextDecoder().decode(await readBody(new Response('exact'), 5)), 'exact');
});

import http from 'node:http';
import https from 'node:https';
import { isIP } from 'node:net';
import { Readable } from 'node:stream';
import { createGunzip, createInflate, createBrotliDecompress } from 'node:zlib';

// Connect to a literal validated address: no runtime-specific dispatcher or second DNS lookup.
export async function requestPinned(url, addresses, { signal, headers = {} } = {}) {
  signal?.throwIfAborted();
  let lastError;
  for (const address of addresses) {
    signal?.throwIfAborted();
    try {
      return await requestAddress(url, address, { signal, headers });
    } catch (error) {
      if (signal?.aborted) throw signal.reason;
      lastError = error;
    }
  }
  throw lastError || new Error('No validated addresses available');
}

function requestAddress(url, address, { signal, headers }) {
  return new Promise((resolve, reject) => {
    const hostname = url.hostname.replace(/^\[|\]$/g, '');
    const request = (url.protocol === 'https:' ? https : http).request({
      protocol: url.protocol,
      hostname: address.address,
      family: address.family,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname + url.search,
      servername: isIP(hostname) ? undefined : hostname,
      headers: { ...headers, Host: url.host, 'Accept-Encoding': 'identity' },
      signal,
      agent: false,
    });
    request.once('error', reject);
    request.once('response', incoming => {
      const responseHeaders = new Headers();
      for (let index = 0; index < incoming.rawHeaders.length; index += 2) {
        responseHeaders.append(incoming.rawHeaders[index], incoming.rawHeaders[index + 1]);
      }
      const encoding = responseHeaders.get('content-encoding')?.trim().toLowerCase();
      let body = incoming;
      const decoders = { gzip: createGunzip, deflate: createInflate, br: createBrotliDecompress };
      if (encoding && encoding !== 'identity') {
        const decoder = decoders[encoding];
        if (!decoder) {
          incoming.destroy();
          reject(new Error(`Unsupported content encoding: ${encoding}`));
          return;
        }
        body = incoming.pipe(decoder());
        incoming.on('error', error => body.destroy(error));
        body.on('close', () => incoming.destroy());
        responseHeaders.delete('content-encoding');
        responseHeaders.delete('content-length');
      }
      // A plain response shape avoids Response's restrictions on empty 204/304 bodies.
      resolve({
        status: incoming.statusCode,
        statusText: incoming.statusMessage || '',
        ok: incoming.statusCode >= 200 && incoming.statusCode < 300,
        headers: responseHeaders,
        body: Readable.toWeb(body),
      });
    });
    request.end();
  });
}

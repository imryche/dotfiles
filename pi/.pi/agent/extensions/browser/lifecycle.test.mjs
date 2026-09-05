import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { connectOrLaunch, connectionRefused, acquireLaunchLock } from './lifecycle.mjs';

const refused = () => new TypeError('fetch failed', { cause: Object.assign(new Error('refused'), { code: 'ECONNREFUSED' }) });
const neverLaunch = () => { throw new Error('unexpected launch/lock'); };

test('already-running browser is reused without locking or launching', async () => {
  const connection = {};
  assert.equal(await connectOrLaunch(async () => connection, { lock: neverLaunch, launch: neverLaunch }), connection);
});

test('explicit endpoints and occupied/malformed endpoints never trigger a launch', async () => {
  const failures = [new Error('Invalid CDP response'), new Error('WebSocket rejected')];
  for (const error of failures) {
    await assert.rejects(connectOrLaunch(async () => { throw error; }, { lock: neverLaunch, launch: neverLaunch }), e => e === error);
  }
  await assert.rejects(connectOrLaunch(async () => { throw refused(); }, {
    explicit: true, lock: neverLaunch, launch: neverLaunch,
  }), /fetch failed/);
  assert.equal(connectionRefused(new AggregateError([refused(), new Error('other')])), false);
  assert.equal(connectionRefused({ code: 'ConnectionRefused' }), true);
});

test('default browser launches once, polls readiness, and releases the lock', async () => {
  let attempts = 0, launches = 0, releases = 0, disposals = 0;
  const connection = {};
  const result = await connectOrLaunch(async () => {
    if (++attempts < 5) throw refused();
    return connection;
  }, {
    lock: async () => async () => { releases++; },
    launch: async () => { launches++; return { check() {}, dispose() { disposals++; } }; },
    pause: async () => {},
  });
  assert.equal(result, connection);
  assert.equal(launches, 1);
  assert.equal(releases, 1);
  assert.equal(disposals, 1);
});

test('rechecks under the lock before launching', async () => {
  let attempts = 0, released = false;
  const connection = {};
  const result = await connectOrLaunch(async () => {
    if (++attempts === 1) throw refused();
    return connection;
  }, {
    lock: async () => async () => { released = true; }, launch: neverLaunch,
  });
  assert.equal(result, connection);
  assert.equal(released, true);
});

test('launch failure and cancellation release the lock without killing Chromium', async () => {
  for (const cancel of [false, true]) {
    const controller = new AbortController();
    let released = false, disposed = false;
    await assert.rejects(connectOrLaunch(async () => { throw refused(); }, {
      signal: controller.signal,
      lock: async () => async () => { released = true; },
      launch: async () => ({
        check() {
          if (cancel) controller.abort(new Error('cancelled startup'));
          else throw new Error('Chromium exited');
        },
        dispose() { disposed = true; },
      }),
      pause: async signal => signal.throwIfAborted(),
    }), cancel ? /cancelled startup/ : /Chromium exited/);
    assert.equal(released, true);
    assert.equal(disposed, true);
  }
});

test('startup timeout reports actionable diagnostics', async () => {
  let released = false;
  await assert.rejects(connectOrLaunch(async () => { throw refused(); }, {
    timeoutMs: 10,
    lock: async () => async () => { released = true; },
    launch: async () => ({ check() {}, dispose() {} }),
  }), /not ready.*launcher.log/);
  assert.equal(released, true);
});

test('two Pi sessions racing to connect launch only one browser', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'pi-browser-race-test-'));
  let ready = false, launches = 0;
  const connection = {};
  const connect = async () => { if (!ready) throw refused(); return connection; };
  const options = {
    lock: signal => acquireLaunchLock(signal, directory),
    launch: async () => {
      launches++;
      await new Promise(resolve => setTimeout(resolve, 30));
      ready = true;
      return { check() {}, dispose() {} };
    },
  };
  try {
    const results = await Promise.all([connectOrLaunch(connect, options), connectOrLaunch(connect, options)]);
    assert.deepEqual(results, [connection, connection]);
    assert.equal(launches, 1);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('kernel lock serializes independent holders and supports cancellation', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'pi-browser-lock-test-'));
  let releaseFirst, releaseSecond;
  try {
    releaseFirst = await acquireLaunchLock(undefined, directory);
    let acquired = false;
    const second = acquireLaunchLock(undefined, directory).then(release => {
      acquired = true; releaseSecond = release; return release;
    });
    await new Promise(resolve => setTimeout(resolve, 50));
    assert.equal(acquired, false);
    await releaseFirst(); releaseFirst = undefined;
    await second;
    assert.equal(acquired, true);
    const controller = new AbortController();
    const waiting = acquireLaunchLock(controller.signal, directory);
    const rejected = assert.rejects(waiting, /stop waiting/);
    controller.abort(new Error('stop waiting'));
    await rejected;
    await releaseSecond(); releaseSecond = undefined;
    const releaseThird = await acquireLaunchLock(undefined, directory);
    await releaseThird();
  } finally {
    await releaseFirst?.(); await releaseSecond?.();
    await rm(directory, { recursive: true, force: true });
  }
});

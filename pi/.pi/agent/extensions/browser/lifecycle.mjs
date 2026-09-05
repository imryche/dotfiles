import { spawn } from 'node:child_process';
import { mkdir, open } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';

export const DEFAULT_ENDPOINT = 'http://127.0.0.1:9222';
export const PROFILE_PATH = join(homedir(), '.local/share/pi-browser');
export const LOG_PATH = join(PROFILE_PATH, 'launcher.log');
const STARTUP_TIMEOUT_MS = 20_000;

export function connectionRefused(error) {
  if (!error || typeof error !== 'object') return false;
  // Node and Bun (the standalone Pi binary) use different error codes.
  if (error.code === 'ECONNREFUSED' || error.code === 'ConnectionRefused') return true;
  if (error.cause && connectionRefused(error.cause)) return true;
  return Array.isArray(error.errors) && error.errors.length > 0 && error.errors.every(connectionRefused);
}

// flock owns the lock in the kernel. No stale PID files, heartbeat, or unsafe lock stealing.
// --no-fork replaces flock with a tiny holder; EOF on stdin releases it if Pi dies.
export async function acquireLaunchLock(signal, profilePath = PROFILE_PATH) {
  signal?.throwIfAborted();
  await mkdir(profilePath, { recursive: true, mode: 0o700 });
  signal?.throwIfAborted();
  return new Promise((resolve, reject) => {
    const holder = spawn('flock', [
      '--exclusive', '--no-fork', '--wait', '20', join(profilePath, '.pi-launch.lock'),
      '/bin/sh', '-c', 'printf "locked\\n"; exec cat >/dev/null',
    ], { stdio: ['pipe', 'pipe', 'pipe'] });
    let acquired = false;
    let stderr = '';
    const onAbort = () => {
      holder.kill('SIGKILL');
      reject(signal.reason);
    };
    const cleanup = () => signal?.removeEventListener('abort', onAbort);
    holder.stderr.on('data', chunk => { stderr = (stderr + chunk).slice(-4096); });
    holder.stdin.on('error', () => {}); // Holder may have exited before release.
    holder.once('error', error => {
      cleanup();
      reject(new Error(`Could not acquire browser launch lock (flock is required): ${error.message}`));
    });
    const closed = new Promise(done => holder.once('close', (code) => {
      cleanup();
      if (!acquired) reject(new Error(`Browser launch lock failed (${code}): ${stderr.trim()}`));
      done();
    }));
    holder.stdout.once('data', () => {
      acquired = true;
      cleanup();
      resolve(async () => { holder.stdin.end(); await closed; });
    });
    signal?.addEventListener('abort', onAbort, { once: true });
    if (signal?.aborted) onAbort();
  });
}

export async function launchChromium(signal) {
  signal?.throwIfAborted();
  await mkdir(PROFILE_PATH, { recursive: true, mode: 0o700 });
  const log = await open(LOG_PATH, 'a', 0o600);
  try {
    signal?.throwIfAborted();
    const child = spawn('chromium', [
      '--remote-debugging-address=127.0.0.1',
      '--remote-debugging-port=9222',
      `--user-data-dir=${PROFILE_PATH}`,
      '--no-first-run',
      '--no-default-browser-check',
    ], { detached: true, stdio: ['ignore', log.fd, log.fd] });
    let failure;
    const onError = error => { failure = new Error(`Could not launch Chromium: ${error.message}`); };
    const onExit = (code, exitSignal) => {
      if (code !== 0) failure = new Error(`Chromium exited (${exitSignal || code}). See ${LOG_PATH}`);
    };
    child.on('error', onError);
    child.on('exit', onExit);
    child.unref();
    return {
      check() { if (failure) throw failure; },
      dispose() { child.removeListener('exit', onExit); },
    };
  } finally {
    await log.close();
  }
}

/** Connect first. Auto-launch only for a refused default endpoint, never a malformed CDP server. */
export async function connectOrLaunch(connect, {
  endpoint = DEFAULT_ENDPOINT,
  explicit = false,
  signal,
  lock = acquireLaunchLock,
  launch = launchChromium,
  pause = signal => delay(250, undefined, { signal }),
  timeoutMs = STARTUP_TIMEOUT_MS,
} = {}) {
  signal?.throwIfAborted();
  try {
    return await connect(endpoint, signal);
  } catch (error) {
    if (explicit || !connectionRefused(error) || signal?.aborted) throw error;
  }

  const timeout = AbortSignal.timeout(timeoutMs);
  const startupSignal = signal ? AbortSignal.any([signal, timeout]) : timeout;
  let release, process;
  try {
    release = await lock(startupSignal);
    // Another Pi session may have launched the browser while we waited for the lock.
    try {
      return await connect(endpoint, startupSignal);
    } catch (error) {
      if (!connectionRefused(error) || startupSignal.aborted) throw error;
    }
    process = await launch(startupSignal);
    while (true) {
      startupSignal.throwIfAborted();
      process.check();
      try {
        return await connect(endpoint, startupSignal);
      } catch (error) {
        if (!connectionRefused(error) || startupSignal.aborted) throw error;
      }
      await pause(startupSignal);
    }
  } catch (error) {
    if (signal?.aborted) throw signal.reason;
    if (timeout.aborted) throw new Error(`Chromium was not ready within ${timeoutMs}ms. See ${LOG_PATH}. If this profile is already open without remote debugging, close that browser and retry.`);
    throw error;
  } finally {
    process?.dispose();
    await release?.();
  }
}

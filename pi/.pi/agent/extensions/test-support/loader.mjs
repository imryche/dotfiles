// Unit tests run without launching Pi. Only the Pi registration/UI boundary is stubbed.
import { registerHooks, stripTypeScriptTypes } from 'node:module';
import { readFileSync } from 'node:fs';

const mocks = {
  'typebox': 'export const Type = new Proxy({}, { get: () => (...args) => args });',
  '@earendil-works/pi-ai': 'export const StringEnum = values => values;',
  '@earendil-works/pi-tui': 'export class Text {}',
  '@earendil-works/pi-coding-agent': `
    export const DEFAULT_MAX_BYTES = 51200, DEFAULT_MAX_LINES = 2000;
    export const formatSize = String;
    export const withFileMutationQueue = async (_path, fn) => fn();
    export const truncateHead = content => ({ content, truncated: false });
  `,
};
registerHooks({
  resolve(specifier, context, next) {
    if (specifier in mocks) return { url: 'pi-test:' + specifier, shortCircuit: true };
    return next(specifier, context);
  },
  load(url, context, next) {
    if (url.startsWith('pi-test:')) return { format: 'module', source: mocks[url.slice(8)], shortCircuit: true };
    if (url.endsWith('/index.ts')) return {
      format: 'module', shortCircuit: true,
      source: stripTypeScriptTypes(readFileSync(new URL(url), 'utf8'), { mode: 'strip' }),
    };
    return next(url, context);
  },
});

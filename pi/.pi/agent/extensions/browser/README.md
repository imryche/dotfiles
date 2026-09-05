# Pi browser tools

Fast Chromium control over a persistent, loopback-only Chrome DevTools Protocol connection.

The extension exposes two tools:

- `browser_snapshot` lists tabs and returns a compact page snapshot with generation-qualified refs such as `e1_<uuid>`.
- `browser_execute` runs a batch of direct DOM actions in the page using those refs.

## Browser lifecycle

No manual startup is needed. The first browser tool call connects to `http://127.0.0.1:9222`. If the connection is refused, Pi launches visible Chromium with the dedicated, persistent `~/.local/share/pi-browser` profile and waits up to 20 seconds for CDP readiness. Logins and browser data stay in this profile; your everyday browser profile is not used.

- `/browser open` connects or launches and brings a tab to the foreground.
- `/browser status` reports availability without launching anything.
- Pi exit, session switches, and `/reload` disconnect CDP but **leave Chromium running**.
- Independent Pi sessions share one browser. A kernel `flock` startup lock prevents simultaneous launches and is released automatically if Pi dies. It does not serialize different sessions' actions on shared tabs.
- `chromium` and `flock` must be on `PATH`, with a graphical desktop available. Launch errors are logged to `~/.local/share/pi-browser/launcher.log`.

The default endpoint is reserved for the Pi browser. An already-running CDP browser there is reused rather than replaced; avoid starting your everyday profile on this port. A malformed/occupied endpoint causes an error, not another launch.

Optional manual startup (same configuration as the automatic launcher):

```bash
chromium \
  --remote-debugging-address=127.0.0.1 \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/.local/share/pi-browser" \
  --no-first-run \
  --no-default-browser-check
```

Set `PI_BROWSER_CDP_URL` to use a separately managed browser; only loopback HTTP(S) endpoints are accepted. **Any explicit endpoint is connect-only**, even if it equals the default: Pi never launches a fallback browser for it. If the Pi profile is already open without remote debugging, close that browser and retry.

## Execution model

Call `browser_snapshot` first. Interactive elements receive refs. Then batch related work into one `browser_execute` call:

```js
// Copy complete refs from the current snapshot, or use CSS selectors:
fill("input[type=email]", "hello@example.com");
click("button[type=submit]");
await waitFor("[data-status=complete]");
return text("[data-status]");
```

Available helpers:

- `ref(id)` and `query(selector)` resolve an element.
- `click(target)`, `fill(target, value)`, and `check(target, checked)` mutate controls directly.
- `text(target)` and `attr(target, name)` read the page.
- `sleep(ms)` and `waitFor(selector, timeout)` wait explicitly.
- Return `goto(url)`, `snapshot()`, `screenshot(options)`, or `recording(options)` to request that operation.

### Scoped snapshots

Take a full snapshot to orient yourself, then inspect just the relevant subtree:

```js
// Arguments to browser_snapshot:
{ selector: "#faq" }

// Inside browser_execute:
return snapshot({ target: "#faq" });
return snapshot({ target: query(".hero__app-preview") });
return snapshot({ target: ref("<complete-ref-from-current-snapshot>") });
return snapshot(); // Back to the whole page.
```

Selectors use the first matching element. Scoped output includes the page title, scope label, and tab list, but walks only the selected subtree. Existing output limits still apply. A missing/invalid selector or detached target throws instead of falling back to the full page.

Every successful snapshot—full or scoped—replaces **all** previous refs for that tab. Failed target resolution preserves existing refs. Resolve ref/element targets before the snapshot, and use the new refs returned by it for subsequent actions. Take a full snapshot again after navigation or when changes elsewhere on the page matter.

Screenshot options:

```js
return screenshot();                                      // current viewport
return screenshot({ fullPage: true });                    // complete document
return screenshot({ target: ".hero", padding: 16 });     // one element
return screenshot({ target: [hero, nextSection] });       // union of elements
return screenshot({ clip: { x: 0, y: 200, width: 1200, height: 800 } });
return screenshot({ target: ".hero", save: true });        // also save a PNG under /tmp
```

Targets may be DOM elements, snapshot refs, CSS selectors, or an array mixing those forms. Target and clip screenshots use document coordinates and preserve the page's native scale.

Saving is opt-in and works with every screenshot mode. `save: true` writes the PNG to a generated `/tmp/pi-browser-screenshot-<uuid>.png` path, returns that path in the result, and still attaches the image. Use it when the user needs a reusable file; omit it for transient visual inspection. Arbitrary output paths are intentionally unsupported.

## Video recording

Recording uses CDP screencast frames, so normal snapshots, actions, screenshots, scrolling, and same-tab navigation continue to work while capture is active:

```js
return recording({ action: "start" });
```

Perform browser actions in subsequent calls, then encode and save the result:

```js
return recording({ action: "status" });
return recording({ action: "stop" });
```

Stopping returns a generated `/tmp/pi-browser-recording-<uuid>.mp4` path. Frames are acknowledged immediately and written asynchronously; MP4 encoding happens only after capture stops so it does not slow browser actions. Recordings are limited to five minutes, capture the selected tab's page viewport without browser chrome or audio, and require `ffmpeg` on `PATH`.

Code runs inside the selected page, not in Pi's Node.js process. Direct DOM actions prioritize speed and do not create trusted mouse or keyboard events. Refs become stale after another snapshot, navigation, or element replacement; take a new snapshot in that case. Tab numbers refer to the most recent snapshot, not a freshly reordered tab list. If a tab closes, take a snapshot without a tab argument to refresh the mapping.

Browser tool calls are serialized within each Pi session. Cancellation stops pending `sleep()`/`waitFor()` helpers on a best-effort basis; it cannot roll back clicks or reliably stop arbitrary JavaScript, native timers, or network requests. Separate Pi sessions' page actions are not coordinated; only browser startup is locked.

## Tests

Run `npm ci` then `npm test` in this directory (Node 22.15+). Tests exercise the actual DOM runtime with LinkeDOM and the CDP/tab lifecycle with fakes; Pi registration/UI imports are stubbed by `../test-support/loader.mjs`. No running browser is required. Startup tests exercise connect/reuse/launch, failure and cancellation, command behavior, and real cross-process `flock` contention. These are regression tests, not full Chromium integration coverage.

CDP provides full control of the dedicated browser profile. Only sign it into services Pi is allowed to access, and treat all page content as untrusted.

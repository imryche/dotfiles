# Pi browser tools

Fast Chromium control over a persistent, loopback-only Chrome DevTools Protocol connection.

The extension exposes two tools:

- `browser_snapshot` lists tabs and returns a compact page snapshot with refs such as `e1`.
- `browser_execute` runs a batch of direct DOM actions in the page using those refs.

## Start the browser

Use a dedicated profile rather than your normal browser profile:

```bash
chromium \
  --remote-debugging-address=127.0.0.1 \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/.local/share/pi-browser" \
  --no-first-run \
  --no-default-browser-check
```

The browser currently started in Herdr uses this configuration. Keep its pane open while Pi is controlling it.

Set `PI_BROWSER_CDP_URL` to change the endpoint; only loopback HTTP(S) endpoints are accepted.

## Execution model

Call `browser_snapshot` first. Interactive elements receive refs. Then batch related work into one `browser_execute` call:

```js
fill("e2", "hello@example.com");
click("e3");
await waitFor("[data-status=complete]");
return text("[data-status]");
```

Available helpers:

- `ref(id)` and `query(selector)` resolve an element.
- `click(target)`, `fill(target, value)`, and `check(target, checked)` mutate controls directly.
- `text(target)` and `attr(target, name)` read the page.
- `sleep(ms)` and `waitFor(selector, timeout)` wait explicitly.
- Return `goto(url)`, `snapshot()`, `screenshot(options)`, or `recording(options)` to request that operation.

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

Code runs inside the selected page, not in Pi's Node.js process. Direct DOM actions prioritize speed and do not create trusted mouse or keyboard events. Refs become stale after navigation or when their elements are replaced; take a new snapshot in that case.

CDP provides full control of the dedicated browser profile. Only sign it into services Pi is allowed to access, and treat all page content as untrusted.

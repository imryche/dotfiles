# Pi web tools

Native Pi tools for compact web search and readable page extraction:

- `web_search` uses the Brave Search API.
- `web_fetch` downloads a public page and extracts Markdown with Defuddle.

## Setup

```bash
cd ~/.pi/agent/extensions/web
npm install
export BRAVE_SEARCH_API_KEY="your-key"
```

Put the environment variable in your shell's private environment configuration, not in this repository. Run `/reload` after installing or changing the extension.

`web_fetch` does not require a Brave API key. It accepts only public HTTP(S) pages on standard ports, validates every redirect, connects directly to validated public IPs via Node-compatible HTTP(S) while preserving Host/TLS SNI (no Undici dispatcher dependency), limits downloads to 5 MiB, and disables Defuddle's third-party network fallbacks. JavaScript rendering and PDFs are intentionally not supported.

Fetch output includes the resolved source URL, title and available author/date metadata. When article extraction is insufficient, a labeled plain-text fallback excludes scripts, styles, navigation, hidden elements and other common clutter. This is static HTML cleanup, not rendered CSS visibility detection.

Both tools report output truncation and save the complete text to a temporary file. The 15-second network deadline covers DNS, redirects and downloading. Cancellation is checked between extraction stages, but synchronous HTML parsing/Defuddle cannot be interrupted mid-stage; this is not a hard extraction timeout.

## Tests

Run `npm ci` then `npm test` here (Node 22.15+). Tests cover URL/IP restrictions, DNS pinning, cancellation, download limits, redirect handling, real Defuddle extraction, cleaned fallback, source metadata, Brave parsing/deduplication, caching and errors, and truncation notice/file wiring. Redirect tests inject transport responses while running the actual redirect loop; they do not make real network requests. A local transport integration test connects to an explicit IP for a nonexistent hostname and checks Host preservation, gzip decoding and manual redirects. Pi registration/UI imports are stubbed by `../test-support/loader.mjs`; no API key or external network is required.

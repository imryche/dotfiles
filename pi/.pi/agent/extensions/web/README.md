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

`web_fetch` does not require a Brave API key. It accepts only public HTTP(S) pages on standard ports, validates every redirect, pins connections to validated public DNS addresses while preserving Host/TLS SNI, limits downloads to 5 MiB, and disables Defuddle's third-party network fallbacks. JavaScript rendering and PDFs are intentionally not supported.

## Tests

Run `npm ci` then `npm test` here (Node 22.15+). Tests cover URL/IP restrictions, DNS pinning, cancellation, and download limits. Pi registration/UI imports are stubbed by `../test-support/loader.mjs`; no API key or external network is required.

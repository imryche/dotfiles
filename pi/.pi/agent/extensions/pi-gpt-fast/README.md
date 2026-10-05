# GPT fast mode

- `/fast` toggles fast mode.
- `/fast on` and `/fast off` explicitly enable or disable it.
- `/fast status` reports the current setting.

Starts off in new sessions. The setting is saved in the session branch and restored on reload, resume, or branch navigation. It stays enabled across model switches. No persistent footer status or extra line is added; commands show notifications, and `/fast status` reports the setting and whether it applies to the selected model.

For any `gpt-*` model on `openai-codex` or `openai`, enabled mode sets `service_tier: "priority"` on each request. Model IDs, authentication, and model catalogs are unchanged; no synthetic `-fast` models or hardcoded model list are used. Other providers and non-GPT models are untouched.

`/fast` is the command name; the wire value is `priority`. Codex rejects `service_tier: "fast"`. Requesting priority processing is not a guarantee that every provider, model, or account supports it. Provider limits and tier-specific pricing may apply. Pi's cost estimates still use the selected model's ordinary catalog prices.

After upgrading from the old alias-based extension, run `/reload`, select a normal GPT model if you were using `gpt-5.5-fast`, and run `/fast on`.

Tests (Node with native TypeScript support):

```sh
node --test pi/.pi/agent/extensions/pi-gpt-fast/index.test.mjs
```

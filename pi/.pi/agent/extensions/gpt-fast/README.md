# GPT Fast mode

`/fast` toggles fast mode and reports the new state. It takes no arguments.

Defaults to off until enabled. `/fast` saves the preference to `~/.local/share/gpt-fast/settings.json`, so it persists across new sessions, reloads, and restarts. Session switches and branch navigation do not change it; old branch-local settings are ignored. It stays enabled across model switches. If saving fails, a warning is shown and the change still applies in the current session. On interactive startup, `GPT Fast mode is on.` is shown when the saved preference is on and the default selected model supports it. No startup notice is shown when it is off or unsupported, or on `/reload`. No persistent footer status is added; toggling shows a notification with the new setting and whether it applies to the selected model.

For any `gpt-*` model on `openai-codex` or `openai`, enabled mode sets `service_tier: "priority"` on each request. Model IDs, authentication, and model catalogs are unchanged; no synthetic `-fast` models or hardcoded model list are used. Other providers and non-GPT models are untouched.

`/fast` is the command name; the wire value is `priority`. Codex rejects `service_tier: "fast"`. Requesting priority processing is not a guarantee that every provider, model, or account supports it. Provider limits and tier-specific pricing may apply. Pi's cost estimates still use the selected model's ordinary catalog prices.

After upgrading from the old alias-based extension, run `/reload`, select a normal GPT model if you were using `gpt-5.5-fast`, and run `/fast` to enable fast mode if it is off.

Tests (Node with native TypeScript support):

```sh
node --test pi/.pi/agent/extensions/gpt-fast/index.test.mjs
```

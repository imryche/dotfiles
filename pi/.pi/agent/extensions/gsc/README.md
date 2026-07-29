# Google Search Console extension for Pi

Read-only Search Console access for properties explicitly granted to a Google Cloud service account and allowlisted locally.

## Tools

- `gsc_list_sites` — list properties visible to the service account
- `gsc_search_analytics` — query clicks, impressions, CTR, and position
- `gsc_inspect_url` — inspect a URL's Google index status
- `gsc_list_sitemaps` — list submitted sitemaps
- `/gsc-status` — show safe local setup status (never displays credentials)

All tools use the read-only OAuth scope `https://www.googleapis.com/auth/webmasters.readonly`. The extension does not provide mutation tools.

## 1. Google setup

1. In Google Cloud, create or select a project.
2. Enable the **Google Search Console API**.
3. Create a dedicated service account and download a JSON key.
4. In Search Console, open each property and add the service-account email under **Settings → Users and permissions**. Give it the minimum access that supports the data you need; Full access is generally needed for all read APIs, including URL Inspection.

Treat the downloaded JSON as a password. Do not paste it into Pi or commit it to source control.

## 2. Store credentials and configuration

```bash
mkdir -p ~/.config/pi-google
mv ~/Downloads/YOUR-KEY.json ~/.config/pi-google/search-console-service-account.json
chmod 600 ~/.config/pi-google/search-console-service-account.json
cp ~/.pi/agent/extensions/gsc/config.example.json \
  ~/.config/pi-google/search-console.json
chmod 600 ~/.config/pi-google/search-console.json
```

Default config location:

```text
~/.config/pi-google/search-console.json
```

Config format:

```json
{
  "credentialsFile": "~/.config/pi-google/search-console-service-account.json",
  "allowedSites": [
    "sc-domain:example.com",
    "https://www.example.com/"
  ],
  "maxRowsPerRequest": 5000,
  "maxDateRangeDays": 550
}
```

Property identifiers must exactly match Search Console:

- Domain property: `sc-domain:example.com`
- URL-prefix property: `https://www.example.com/`

You may initially leave `allowedSites` empty and ask Pi to list visible properties. Only `gsc_list_sites` works without an allowlist; all data-reading tools require the exact property to be allowlisted.

Environment overrides:

- `GSC_CONFIG_FILE` — alternate config path
- `GSC_SERVICE_ACCOUNT_FILE` — alternate credential path
- `GOOGLE_APPLICATION_CREDENTIALS` — credential fallback

## 3. Install and load

Run `npm install` in this directory, then restart Pi or run `/reload`:

```bash
cd ~/.pi/agent/extensions/gsc
npm install
```

Check setup:

```text
/gsc-status
```

Then ask:

```text
List my Search Console properties.
```

Copy the exact desired property identifiers into `allowedSites`, run `/reload`, and query them.

## Security and output behavior

- Credentials are loaded locally and never intentionally included in tool results.
- Every data tool checks `allowedSites` before making an API request.
- Date ranges and per-request rows are capped by local configuration.
- Tool output is capped at Pi's 2,000-line/50 KB limit. Large API responses are not written to temporary files because Search Console data may be sensitive. Use a smaller `rowLimit` and `startRow` to paginate.
- Pi session files will contain query parameters and returned Search Console data. Protect `~/.pi/agent/sessions/` accordingly.

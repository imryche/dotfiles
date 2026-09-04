import { access, readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { resolve } from "node:path";
import { StringEnum } from "@earendil-works/pi-ai";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  formatSize,
  truncateHead,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import type { google } from "googleapis";
import { Type } from "typebox";

const READONLY_SCOPE = "https://www.googleapis.com/auth/webmasters.readonly";
const DEFAULT_CONFIG_FILE = "~/.config/pi-google/search-console.json";
const DEFAULT_MAX_ROWS = 5_000;
const GOOGLE_MAX_ROWS = 25_000;
const DEFAULT_MAX_DATE_RANGE_DAYS = 550;

interface GscConfig {
  credentialsFile: string;
  allowedSites: string[];
  maxRowsPerRequest: number;
  maxDateRangeDays: number;
  configFile: string;
}

interface Runtime {
  config: GscConfig;
  webmasters: ReturnType<typeof google.webmasters>;
  searchconsole: ReturnType<typeof google.searchconsole>;
}

const dimensions = ["date", "query", "page", "country", "device", "searchAppearance", "hour"] as const;
const searchTypes = ["web", "image", "video", "news", "discover", "googleNews"] as const;
const aggregationTypes = ["auto", "byProperty", "byPage", "newsShowcasePanel"] as const;
const dataStates = ["final", "all", "hourly_all"] as const;
const filterDimensions = ["query", "page", "country", "device", "searchAppearance"] as const;
const filterOperators = ["contains", "equals", "notContains", "notEquals", "includingRegex", "excludingRegex"] as const;

const siteUrlParameter = Type.String({
  description: "Exact Search Console property identifier, e.g. sc-domain:example.com or https://www.example.com/",
});

const SearchAnalyticsParameters = Type.Object({
  siteUrl: siteUrlParameter,
  startDate: Type.String({ description: "Start date in YYYY-MM-DD format (inclusive)" }),
  endDate: Type.String({ description: "End date in YYYY-MM-DD format (inclusive)" }),
  dimensions: Type.Optional(Type.Array(StringEnum(dimensions), {
    description: "Dimensions in grouping order; omit for property totals",
    maxItems: 7,
    uniqueItems: true,
  })),
  searchType: Type.Optional(StringEnum(searchTypes, { description: "Search result type; defaults to web" })),
  aggregationType: Type.Optional(StringEnum(aggregationTypes)),
  dataState: Type.Optional(StringEnum(dataStates, { description: "final for finalized data; all may include fresh data" })),
  rowLimit: Type.Optional(Type.Integer({
    description: `Rows to request (1-${GOOGLE_MAX_ROWS}); also limited by local config`,
    minimum: 1,
    maximum: GOOGLE_MAX_ROWS,
  })),
  startRow: Type.Optional(Type.Integer({ description: "Zero-based pagination offset", minimum: 0 })),
  filterGroups: Type.Optional(Type.Array(Type.Object({
    groupType: Type.Optional(StringEnum(["and"] as const)),
    filters: Type.Array(Type.Object({
      dimension: StringEnum(filterDimensions),
      operator: StringEnum(filterOperators),
      expression: Type.String({ description: "Filter value or RE2 regular expression for regex operators" }),
    }), { minItems: 1 }),
  }), { description: "Dimension filters; Search Console currently combines groups with AND" })),
});

function expandHome(path: string): string {
  if (path === "~") return homedir();
  if (path.startsWith("~/")) return resolve(homedir(), path.slice(2));
  return resolve(path);
}

function positiveInteger(value: unknown, fallback: number, maximum?: number): number {
  if (value === undefined) return fallback;
  if (!Number.isInteger(value) || Number(value) < 1 || (maximum !== undefined && Number(value) > maximum)) {
    throw new Error(`Expected a positive integer${maximum ? ` no greater than ${maximum}` : ""}, got ${String(value)}`);
  }
  return Number(value);
}

async function loadConfig(): Promise<GscConfig> {
  const configFile = expandHome(process.env.GSC_CONFIG_FILE || DEFAULT_CONFIG_FILE);
  let parsed: unknown;
  try {
    parsed = JSON.parse(await readFile(configFile, "utf8"));
  } catch (error: any) {
    if (error?.code === "ENOENT") {
      throw new Error(
        `Search Console config not found at ${configFile}. See ~/.pi/agent/extensions/google-search-console/README.md`,
      );
    }
    throw new Error(`Cannot read Search Console config ${configFile}: ${error?.message || String(error)}`);
  }

  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error(`Search Console config ${configFile} must contain a JSON object`);
  }

  const raw = parsed as Record<string, unknown>;
  const credentialsSetting =
    process.env.GSC_SERVICE_ACCOUNT_FILE ||
    (typeof raw.credentialsFile === "string" ? raw.credentialsFile : "") ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (!credentialsSetting) {
    throw new Error(
      "No service-account credential file configured. Set credentialsFile in the GSC config or GSC_SERVICE_ACCOUNT_FILE.",
    );
  }

  if (!Array.isArray(raw.allowedSites) || !raw.allowedSites.every((site) => typeof site === "string" && site.length > 0)) {
    throw new Error("allowedSites must be an array of exact, non-empty Search Console property identifiers");
  }

  const credentialsFile = expandHome(credentialsSetting);
  try {
    await access(credentialsFile);
  } catch {
    throw new Error(`Service-account credential file is not readable: ${credentialsFile}`);
  }

  return {
    credentialsFile,
    allowedSites: [...new Set(raw.allowedSites as string[])],
    maxRowsPerRequest: positiveInteger(raw.maxRowsPerRequest, DEFAULT_MAX_ROWS, GOOGLE_MAX_ROWS),
    maxDateRangeDays: positiveInteger(raw.maxDateRangeDays, DEFAULT_MAX_DATE_RANGE_DAYS),
    configFile,
  };
}

function assertAllowed(config: GscConfig, siteUrl: string): void {
  if (!config.allowedSites.includes(siteUrl)) {
    throw new Error(
      `Search Console property is not allowlisted: ${siteUrl}. Add the exact identifier to allowedSites in ${config.configFile} and run /reload.`,
    );
  }
}

function parseIsoDate(value: string, field: string): Date {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new Error(`${field} must use YYYY-MM-DD format`);
  }
  const date = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new Error(`${field} is not a valid calendar date: ${value}`);
  }
  return date;
}

function validateDateRange(startDate: string, endDate: string, maxDays: number): void {
  const start = parseIsoDate(startDate, "startDate");
  const end = parseIsoDate(endDate, "endDate");
  const days = Math.floor((end.getTime() - start.getTime()) / 86_400_000) + 1;
  if (days < 1) throw new Error("endDate must not be before startDate");
  if (days > maxDays) {
    throw new Error(`Requested ${days} days; local configuration allows at most ${maxDays}`);
  }
}

function apiError(operation: string, error: any): Error {
  const message =
    error?.response?.data?.error?.message ||
    error?.errors?.[0]?.message ||
    error?.message ||
    String(error);
  return new Error(`${operation} failed: ${message}`);
}

function output(payload: unknown, details: Record<string, unknown> = {}) {
  const serialized = JSON.stringify(payload, null, 2);
  const truncation = truncateHead(serialized, {
    maxLines: DEFAULT_MAX_LINES,
    maxBytes: DEFAULT_MAX_BYTES,
  });

  let text = truncation.content;
  if (truncation.truncated) {
    text += `\n\n[Output truncated to ${truncation.outputLines} lines / ${formatSize(truncation.outputBytes)} `;
    text += `(from ${truncation.totalLines} lines / ${formatSize(truncation.totalBytes)}). `;
    text += "No full-data temp file was written. Request fewer rows or paginate with startRow.]";
  }

  return {
    content: [{ type: "text" as const, text }],
    details: {
      ...details,
      truncated: truncation.truncated,
      outputRows: truncation.outputLines,
      totalOutputRows: truncation.totalLines,
    },
  };
}

export default function (pi: ExtensionAPI) {
  let runtimePromise: Promise<Runtime> | undefined;

  function getRuntime(): Promise<Runtime> {
    if (!runtimePromise) {
      runtimePromise = (async () => {
        const [{ google }, config] = await Promise.all([import("googleapis"), loadConfig()]);
        const auth = new google.auth.GoogleAuth({
          keyFile: config.credentialsFile,
          scopes: [READONLY_SCOPE],
        });
        return {
          config,
          webmasters: google.webmasters({ version: "v3", auth }),
          searchconsole: google.searchconsole({ version: "v1", auth }),
        };
      })().catch((error) => {
        runtimePromise = undefined;
        throw error;
      });
    }
    return runtimePromise;
  }

  pi.registerTool({
    name: "gsc_list_sites",
    label: "GSC Sites",
    description: "List Google Search Console properties visible to the configured service account and show which are locally allowlisted. This is the only GSC tool that can run before a property is allowlisted.",
    parameters: Type.Object({}),
    async execute() {
      const { config, webmasters } = await getRuntime();
      try {
        const response = await webmasters.sites.list();
        const sites = (response.data.siteEntry || []).map((site) => ({
          siteUrl: site.siteUrl,
          permissionLevel: site.permissionLevel,
          allowed: typeof site.siteUrl === "string" && config.allowedSites.includes(site.siteUrl),
        }));
        return output({ sites, count: sites.length }, { siteCount: sites.length });
      } catch (error) {
        throw apiError("Listing Search Console properties", error);
      }
    },
  });

  pi.registerTool({
    name: "gsc_search_analytics",
    label: "GSC Search Analytics",
    description: `Query read-only Search Console performance data (clicks, impressions, CTR, and average position). Output is truncated to ${DEFAULT_MAX_LINES} lines or ${formatSize(DEFAULT_MAX_BYTES)}; use rowLimit and startRow to paginate. The property must be locally allowlisted.`,
    parameters: SearchAnalyticsParameters,
    async execute(_toolCallId, params) {
      const { config, webmasters } = await getRuntime();
      assertAllowed(config, params.siteUrl);
      validateDateRange(params.startDate, params.endDate, config.maxDateRangeDays);

      const rowLimit = params.rowLimit ?? Math.min(1_000, config.maxRowsPerRequest);
      if (rowLimit > config.maxRowsPerRequest) {
        throw new Error(`rowLimit ${rowLimit} exceeds the local maximum of ${config.maxRowsPerRequest}`);
      }
      const startRow = params.startRow ?? 0;

      const requestBody: Record<string, unknown> = {
        startDate: params.startDate,
        endDate: params.endDate,
        rowLimit,
        startRow,
      };
      if (params.dimensions !== undefined) requestBody.dimensions = params.dimensions;
      if (params.searchType !== undefined) requestBody.type = params.searchType;
      if (params.aggregationType !== undefined) requestBody.aggregationType = params.aggregationType;
      if (params.dataState !== undefined) requestBody.dataState = params.dataState;
      if (params.filterGroups !== undefined) {
        requestBody.dimensionFilterGroups = params.filterGroups.map((group) => ({
          groupType: group.groupType ?? "and",
          filters: group.filters,
        }));
      }

      try {
        const response = await webmasters.searchanalytics.query({
          siteUrl: params.siteUrl,
          requestBody,
        });
        const rows = response.data.rows || [];
        const payload = {
          siteUrl: params.siteUrl,
          startDate: params.startDate,
          endDate: params.endDate,
          dimensions: params.dimensions || [],
          responseAggregationType: response.data.responseAggregationType,
          rowCount: rows.length,
          startRow,
          requestedRowLimit: rowLimit,
          nextStartRow: rows.length === rowLimit ? startRow + rows.length : null,
          rows: rows.map((row) => ({
            keys: row.keys,
            clicks: row.clicks,
            impressions: row.impressions,
            ctr: row.ctr,
            position: row.position,
          })),
        };
        return output(payload, {
          siteUrl: params.siteUrl,
          rowCount: rows.length,
          startRow,
          nextStartRow: payload.nextStartRow,
        });
      } catch (error) {
        throw apiError("Search Analytics query", error);
      }
    },
  });

  pi.registerTool({
    name: "gsc_inspect_url",
    label: "GSC URL Inspection",
    description: "Inspect a URL's current Google index status using the read-only Search Console URL Inspection API. The containing property must be locally allowlisted.",
    parameters: Type.Object({
      siteUrl: siteUrlParameter,
      inspectionUrl: Type.String({ description: "Fully qualified URL to inspect" }),
      languageCode: Type.Optional(Type.String({ description: "Optional BCP-47 response language, e.g. en-US" })),
    }),
    async execute(_toolCallId, params) {
      const { config, searchconsole } = await getRuntime();
      assertAllowed(config, params.siteUrl);
      let inspectionUrl: URL;
      try {
        inspectionUrl = new URL(params.inspectionUrl);
      } catch {
        throw new Error(`inspectionUrl is not a valid absolute URL: ${params.inspectionUrl}`);
      }
      if (!['http:', 'https:'].includes(inspectionUrl.protocol)) {
        throw new Error("inspectionUrl must use http or https");
      }

      try {
        const response = await searchconsole.urlInspection.index.inspect({
          requestBody: {
            siteUrl: params.siteUrl,
            inspectionUrl: inspectionUrl.toString(),
            ...(params.languageCode ? { languageCode: params.languageCode } : {}),
          },
        });
        return output(response.data, {
          siteUrl: params.siteUrl,
          inspectionUrl: inspectionUrl.toString(),
        });
      } catch (error) {
        throw apiError("URL Inspection", error);
      }
    },
  });

  pi.registerTool({
    name: "gsc_list_sitemaps",
    label: "GSC Sitemaps",
    description: "List submitted sitemaps and their read-only status for an allowlisted Search Console property.",
    parameters: Type.Object({
      siteUrl: siteUrlParameter,
      sitemapIndexUrl: Type.Optional(Type.String({ description: "Optional sitemap index URL used to filter child sitemaps" })),
    }),
    async execute(_toolCallId, params) {
      const { config, webmasters } = await getRuntime();
      assertAllowed(config, params.siteUrl);
      try {
        const response = await webmasters.sitemaps.list({
          siteUrl: params.siteUrl,
          ...(params.sitemapIndexUrl ? { sitemapIndex: params.sitemapIndexUrl } : {}),
        });
        const sitemaps = response.data.sitemap || [];
        return output({ siteUrl: params.siteUrl, count: sitemaps.length, sitemaps }, {
          siteUrl: params.siteUrl,
          sitemapCount: sitemaps.length,
        });
      } catch (error) {
        throw apiError("Listing sitemaps", error);
      }
    },
  });

  pi.registerCommand("gsc-status", {
    description: "Show Google Search Console extension setup status without exposing credentials",
    async handler(_args, ctx) {
      try {
        const config = await loadConfig();
        ctx.ui.notify(
          `GSC ready: ${config.allowedSites.length} allowlisted site(s), max ${config.maxRowsPerRequest} rows, config ${config.configFile}`,
          "info",
        );
      } catch (error: any) {
        ctx.ui.notify(error?.message || String(error), "error");
      }
    },
  });
}

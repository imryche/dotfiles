import { randomUUID } from "node:crypto";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

async function readPreference(path: string): Promise<boolean> {
  try {
    const settings: unknown = JSON.parse(await readFile(path, "utf8"));
    return !!settings && typeof settings === "object" && !Array.isArray(settings) &&
      (settings as { enabled?: unknown }).enabled === true;
  } catch (error) {
    if (error instanceof SyntaxError || (error as NodeJS.ErrnoException).code === "ENOENT") return false;
    throw error;
  }
}

async function writePreference(path: string, enabled: boolean): Promise<void> {
  await mkdir(dirname(path), { recursive: true, mode: 0o700 });
  const temporary = `${path}.${randomUUID()}.tmp`;
  try {
    await writeFile(temporary, JSON.stringify({ enabled }, null, 2) + "\n", { mode: 0o600 });
    await rename(temporary, path);
  } finally {
    await rm(temporary, { force: true });
  }
}

function supportsFastMode(model: ExtensionContext["model"]): boolean {
  return !!model &&
    (model.provider === "openai-codex" || model.provider === "openai") &&
    model.id.startsWith("gpt-");
}

export default function (
  pi: ExtensionAPI,
  settingsPath = join(homedir(), ".local", "share", "gpt-fast", "settings.json"),
) {
  let enabled = false;

  const clearStatus = (ctx: ExtensionContext) => {
    if (ctx.hasUI) ctx.ui.setStatus("gpt-fast", undefined);
  };

  pi.on("session_start", async (event, ctx) => {
    try {
      enabled = await readPreference(settingsPath);
    } catch (error) {
      ctx.ui.notify(`GPT Fast mode preference could not be loaded (${String(error)}).`, "warning");
    }
    clearStatus(ctx);
    if (event.reason === "startup" && ctx.mode === "tui" && ctx.hasUI && enabled && supportsFastMode(ctx.model)) {
      ctx.ui.notify("GPT Fast mode is on.", "info");
    }
  });

  for (const event of ["session_switch", "session_tree", "session_fork"] as const) {
    pi.on(event, (_event, ctx) => clearStatus(ctx));
  }

  pi.registerCommand("fast", {
    description: "Toggle GPT Fast mode",
    handler: async (args, ctx) => {
      if (args.trim()) {
        ctx.ui.notify("Usage: /fast", "warning");
        return;
      }

      enabled = !enabled;
      try {
        await writePreference(settingsPath, enabled);
      } catch (error) {
        ctx.ui.notify(
          `GPT Fast mode preference not saved (${String(error)}). The change only applies until reload or restart.`,
          "warning",
        );
      }
      clearStatus(ctx);

      const inactive = enabled && !supportsFastMode(ctx.model);
      ctx.ui.notify(
        `GPT Fast mode is ${enabled ? "on" : "off"}.${inactive ? " Select a GPT model to use it." : ""}`,
        "info",
      );
    },
  });

  pi.on("before_provider_request", (event, ctx) => {
    if (!enabled || !supportsFastMode(ctx.model)) return;
    if (!event.payload || typeof event.payload !== "object" || Array.isArray(event.payload)) return;

    return {
      ...(event.payload as Record<string, unknown>),
      service_tier: "priority",
    };
  });
}

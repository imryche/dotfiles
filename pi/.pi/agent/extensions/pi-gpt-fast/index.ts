import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATE_TYPE = "gpt-fast-state";

interface FastState {
  enabled: boolean;
}

function supportsFastMode(model: ExtensionContext["model"]): boolean {
  return !!model &&
    (model.provider === "openai-codex" || model.provider === "openai") &&
    model.id.startsWith("gpt-");
}

export default function (pi: ExtensionAPI) {
  let enabled = false;

  const clearStatus = (ctx: ExtensionContext) => {
    // Clear the old footer indicator when reloading from earlier versions.
    if (ctx.hasUI) ctx.ui.setStatus("gpt-fast", undefined);
  };

  const restoreState = (_event: unknown, ctx: ExtensionContext) => {
    enabled = false;
    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type !== "custom" || entry.customType !== STATE_TYPE) continue;
      const data = entry.data as FastState | undefined;
      if (typeof data?.enabled === "boolean") enabled = data.enabled;
    }
    clearStatus(ctx);
  };

  pi.on("session_start", restoreState);
  pi.on("session_switch", restoreState);
  pi.on("session_tree", restoreState);
  pi.on("session_fork", restoreState);

  pi.registerCommand("fast", {
    description: "Toggle GPT fast mode (/fast [on|off|status])",
    handler: async (args, ctx) => {
      const action = args.trim().toLowerCase();
      if (!["", "on", "off", "status"].includes(action)) {
        ctx.ui.notify("Usage: /fast [on|off|status]", "warning");
        return;
      }

      if (action !== "status") {
        enabled = action === "" ? !enabled : action === "on";
        pi.appendEntry<FastState>(STATE_TYPE, { enabled });
      }
      clearStatus(ctx);

      const inactive = enabled && !supportsFastMode(ctx.model);
      ctx.ui.notify(
        `GPT fast mode ${enabled ? "on" : "off"}.${inactive ? " Applies when you select a GPT model on OpenAI/Codex." : ""}`,
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

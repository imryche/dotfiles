import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PATCH_MARKER = "__hideMcpStatusPatched";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    const ui = ctx.ui as typeof ctx.ui & Record<string, unknown>;

    if (ui[PATCH_MARKER]) {
      ctx.ui.setStatus("mcp", undefined);
      return;
    }

    const setStatus = ctx.ui.setStatus.bind(ctx.ui);

    // Clear any status added before this extension loaded, then prevent the MCP
    // adapter from adding it again when servers connect or disconnect.
    setStatus("mcp", undefined);
    ctx.ui.setStatus = (key, text) => {
      if (key !== "mcp") setStatus(key, text);
    };

    ui[PATCH_MARKER] = true;
  });
}

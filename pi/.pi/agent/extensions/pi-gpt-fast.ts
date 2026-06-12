import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getModel, getModels } from "@earendil-works/pi-ai";
import { openaiCodexOAuthProvider } from "@earendil-works/pi-ai/oauth";

const PROVIDER = "openai-codex";
const BASE_MODEL = "gpt-5.5";
const FAST_MODEL = "gpt-5.5-fast";

export default function (pi: ExtensionAPI) {
  const baseModel = getModel(PROVIDER, BASE_MODEL);
  const existingModels = getModels(PROVIDER);

  pi.registerProvider(PROVIDER, {
    name: "ChatGPT Plus/Pro (Codex Subscription)",
    baseUrl: baseModel.baseUrl,
    api: baseModel.api,
    oauth: openaiCodexOAuthProvider,
    models: existingModels.some((model) => model.id === FAST_MODEL)
      ? existingModels
      : [
          ...existingModels,
          {
            ...baseModel,
            id: FAST_MODEL,
            name: "GPT-5.5 Fast",
            cost: {
              input: baseModel.cost.input * 2.5,
              output: baseModel.cost.output * 2.5,
              cacheRead: baseModel.cost.cacheRead * 2.5,
              cacheWrite: baseModel.cost.cacheWrite * 2.5,
            },
          },
        ],
  });

  pi.on("before_provider_request", (event, ctx) => {
    if (ctx.model?.provider !== PROVIDER || ctx.model.id !== FAST_MODEL) return;
    if (!event.payload || typeof event.payload !== "object" || Array.isArray(event.payload)) return;

    return {
      ...(event.payload as Record<string, unknown>),
      model: BASE_MODEL,
      service_tier: "priority",
    };
  });
}

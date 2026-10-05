import assert from "node:assert/strict";
import { test } from "node:test";
import extension from "./index.ts";

function harness(model = { provider: "openai-codex", id: "gpt-5.5" }) {
  const handlers = new Map();
  const commands = new Map();
  const entries = [];
  const statuses = new Map();
  const notifications = [];
  const ctx = {
    model,
    hasUI: true,
    sessionManager: { getBranch: () => entries },
    ui: {
      setStatus: (key, value) => statuses.set(key, value),
      notify: (...args) => notifications.push(args),
    },
  };
  extension({
    on: (name, handler) => handlers.set(name, handler),
    registerCommand: (name, command) => commands.set(name, command),
    appendEntry: (customType, data) => entries.push({ type: "custom", customType, data }),
  });
  return {
    ctx, entries, statuses, notifications,
    emit: (name, event = {}) => handlers.get(name)?.(event, ctx),
    fast: (args = "") => commands.get("fast").handler(args, ctx),
    request: (payload = { model: ctx.model?.id }) =>
      handlers.get("before_provider_request")({ payload }, ctx),
  };
}

test("starts disabled; toggles priority without changing the model or original payload", async () => {
  const h = harness();
  const payload = Object.freeze({ model: "gpt-5.5", service_tier: "auto", stream: true });
  assert.equal(h.request(payload), undefined);
  await h.fast();
  assert.deepEqual(h.request(payload), { ...payload, service_tier: "priority" });
  assert.equal(payload.service_tier, "auto");
  assert.equal(h.ctx.model.id, "gpt-5.5");
  assert.equal(h.statuses.get("gpt-fast"), undefined);
  await h.fast();
  assert.equal(h.request(payload), undefined);
  assert.equal(h.statuses.get("gpt-fast"), undefined);
});

test("applies dynamically to current and future GPT models across model switches", async () => {
  const h = harness();
  await h.fast("on");
  for (const provider of ["openai-codex", "openai"]) {
    for (const id of ["gpt-5.1-codex-mini", "gpt-5.4", "gpt-5.5", "gpt-99-future"]) {
      h.ctx.model = { provider, id };
      h.emit("model_select", { model: h.ctx.model });
      assert.deepEqual(h.request(), { model: id, service_tier: "priority" });
    }
  }
});

test("leaves other models/providers untouched but stays enabled for switching back", async () => {
  const h = harness();
  await h.fast("on");
  for (const model of [
    { provider: "anthropic", id: "claude-sonnet" },
    { provider: "openrouter", id: "gpt-5.5" },
    { provider: "openai", id: "o3" },
    undefined,
  ]) {
    h.ctx.model = model;
    h.emit("model_select", { model });
    assert.equal(h.request(), undefined);
    assert.equal(h.statuses.get("gpt-fast"), undefined);
  }
  h.ctx.model = { provider: "openai-codex", id: "gpt-5.4" };
  assert.equal(h.request().service_tier, "priority");
});

test("explicit commands are idempotent; status and invalid arguments do not change state", async () => {
  const h = harness();
  await h.fast(" ON ");
  await h.fast("on");
  assert.equal(h.request().service_tier, "priority");
  const count = h.entries.length;
  await h.fast("status");
  await h.fast("invalid");
  assert.equal(h.entries.length, count);
  assert.equal(h.request().service_tier, "priority");
  assert.equal(h.notifications.at(-1)[1], "warning");
  await h.fast("off");
  await h.fast("off");
  assert.equal(h.request(), undefined);
});

test("can arm fast mode on an unsupported model", async () => {
  const h = harness({ provider: "anthropic", id: "claude-sonnet" });
  await h.fast("on");
  assert.match(h.notifications.at(-1)[0], /Applies when you select a GPT model/);
  assert.equal(h.request(), undefined);
  h.ctx.model = { provider: "openai", id: "gpt-5.5" };
  assert.equal(h.request().service_tier, "priority");
});

test("restores branch-local state on reload, session switch, tree navigation and fork", async () => {
  const h = harness();
  for (const event of ["session_start", "session_switch", "session_tree", "session_fork"]) {
    h.entries.splice(0);
    h.emit(event);
    assert.equal(h.request(), undefined);
    h.entries.push({ type: "custom", customType: "gpt-fast-state", data: { enabled: true } });
    h.emit(event);
    assert.equal(h.request().service_tier, "priority");
    h.entries.push({ type: "custom", customType: "gpt-fast-state", data: { enabled: false } });
    h.entries.push({ type: "custom", customType: "unrelated", data: { enabled: true } });
    h.entries.push({ type: "custom", customType: "gpt-fast-state", data: null });
    h.emit(event);
    assert.equal(h.request(), undefined);
  }
});

test("clears the old footer status on reload and never adds one", async () => {
  const h = harness();
  h.statuses.set("gpt-fast", "GPT fast: on");
  h.emit("session_start");
  assert.equal(h.statuses.get("gpt-fast"), undefined);
  h.ctx.ui.setStatus = (key, value) => {
    assert.equal(key, "gpt-fast");
    assert.equal(value, undefined);
  };
  await h.fast("on");
  await h.fast("status");
  assert.equal(h.notifications.at(-1)[0], "GPT fast mode on.");
  await h.fast("off");
  assert.equal(h.notifications.at(-1)[0], "GPT fast mode off.");
});

test("ignores malformed payloads and works without terminal UI", async () => {
  const h = harness();
  h.ctx.hasUI = false;
  h.ctx.ui.setStatus = () => { throw new Error("No terminal UI"); };
  h.emit("session_start");
  await h.fast("on");
  for (const payload of [null, false, 42, "payload", []]) {
    assert.equal(h.request(payload), undefined);
  }
  assert.equal(h.request().service_tier, "priority");
});

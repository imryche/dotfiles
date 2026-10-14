import assert from "node:assert/strict";
import { after, test } from "node:test";
import { mkdtempSync, rmSync } from "node:fs";
import { mkdir, readFile, readdir, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import extension from "./index.ts";

const testDirectory = mkdtempSync(join(tmpdir(), "gpt-fast-test-"));
after(() => rmSync(testDirectory, { recursive: true, force: true }));
let nextHarness = 0;

function harness(
  model = { provider: "openai-codex", id: "gpt-5.5" },
  settingsPath = join(testDirectory, String(nextHarness++), "settings.json"),
) {
  const handlers = new Map();
  const commands = new Map();
  const entries = [];
  const statuses = new Map();
  const notifications = [];
  const ctx = {
    model,
    mode: "tui",
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
    appendEntry: () => { throw new Error("Preferences must not be stored in session branches"); },
  }, settingsPath);
  return {
    ctx, entries, statuses, notifications, settingsPath,
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
  await h.fast();
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
  await h.fast();
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

test("whitespace-only arguments toggle and report the new state", async () => {
  const h = harness();
  await h.fast("  ");
  assert.equal(h.request().service_tier, "priority");
  assert.equal(h.notifications.at(-1)[0], "GPT Fast mode is on.");
  await h.fast("\t");
  assert.equal(h.request(), undefined);
  assert.equal(h.notifications.at(-1)[0], "GPT Fast mode is off.");
});

test("can arm fast mode on an unsupported model", async () => {
  const h = harness({ provider: "anthropic", id: "claude-sonnet" });
  await h.fast();
  assert.equal(h.notifications.at(-1)[0], "GPT Fast mode is on. Select a GPT model to use it.");
  assert.equal(h.request(), undefined);
  h.ctx.model = { provider: "openai", id: "gpt-5.5" };
  assert.equal(h.request().service_tier, "priority");
});

test("persists on and off across reloads, restarts and new sessions", async () => {
  const h = harness();
  await h.emit("session_start");
  assert.equal(h.request(), undefined);
  await h.fast();
  assert.deepEqual(JSON.parse(await readFile(h.settingsPath, "utf8")), { enabled: true });
  assert.equal((await stat(h.settingsPath)).mode & 0o777, 0o600);
  assert.deepEqual(await readdir(dirname(h.settingsPath)), ["settings.json"]);

  const restarted = harness(undefined, h.settingsPath);
  await restarted.emit("session_start");
  assert.equal(restarted.request().service_tier, "priority");
  await restarted.fast();
  await h.emit("session_start");
  assert.equal(h.request(), undefined);

  const newSession = harness(undefined, h.settingsPath);
  await newSession.emit("session_start");
  assert.equal(newSession.request(), undefined);
  await newSession.fast();
  await h.emit("session_start");
  assert.equal(h.request().service_tier, "priority");
});

test("startup announces saved fast mode for supported default models", async () => {
  const saved = harness();
  await saved.fast();
  for (const provider of ["openai-codex", "openai"]) {
    const started = harness({ provider, id: "gpt-5.5" }, saved.settingsPath);
    await started.emit("session_start", { reason: "startup" });
    assert.deepEqual(started.notifications, [["GPT Fast mode is on.", "info"]]);
    assert.equal(started.request().service_tier, "priority");
    assert.equal(started.statuses.get("gpt-fast"), undefined);
  }
});

test("startup stays quiet when fast mode is off or the model is unsupported", async () => {
  const saved = harness();
  await saved.emit("session_start", { reason: "startup" });
  assert.deepEqual(saved.notifications, []);
  await saved.fast();
  for (const model of [
    { provider: "anthropic", id: "claude-sonnet" },
    { provider: "openrouter", id: "gpt-5.5" },
    { provider: "openai", id: "o3" },
  ]) {
    const started = harness(model, saved.settingsPath);
    await started.emit("session_start", { reason: "startup" });
    assert.deepEqual(started.notifications, []);
  }
  const noModel = harness(undefined, saved.settingsPath);
  noModel.ctx.model = undefined;
  await noModel.emit("session_start", { reason: "startup" });
  assert.deepEqual(noModel.notifications, []);
});

test("startup notice is not repeated on reload or sent to non-TUI modes", async () => {
  const saved = harness();
  await saved.fast();
  const reloaded = harness(undefined, saved.settingsPath);
  await reloaded.emit("session_start", { reason: "reload" });
  assert.deepEqual(reloaded.notifications, []);
  assert.equal(reloaded.request().service_tier, "priority");
  for (const mode of ["rpc", "json", "print"]) {
    const started = harness(undefined, saved.settingsPath);
    started.ctx.mode = mode;
    await started.emit("session_start", { reason: "startup" });
    assert.deepEqual(started.notifications, []);
    assert.equal(started.request().service_tier, "priority");
  }
  const noUI = harness(undefined, saved.settingsPath);
  noUI.ctx.hasUI = false;
  await noUI.emit("session_start", { reason: "startup" });
  assert.deepEqual(noUI.notifications, []);
});

test("old branch entries never override the global preference", async () => {
  const h = harness();
  h.entries.push({ type: "custom", customType: "gpt-fast-state", data: { enabled: true } });
  await h.emit("session_start");
  assert.equal(h.request(), undefined);
  await h.fast();
  for (const event of ["session_start", "session_switch", "session_tree", "session_fork"]) {
    h.entries.splice(0);
    h.entries.push({ type: "custom", customType: "gpt-fast-state", data: { enabled: false } });
    await h.emit(event);
    assert.equal(h.request().service_tier, "priority");
  }
});

test("missing, malformed and non-boolean settings default to off", async () => {
  const h = harness();
  await h.emit("session_start");
  assert.equal(h.request(), undefined);
  await mkdir(dirname(h.settingsPath), { recursive: true });
  for (const content of ["broken json", "null", "true", "[]", "{}", '{"enabled":"true"}', '{"enabled":1}']) {
    await writeFile(h.settingsPath, content);
    await h.emit("session_start");
    assert.equal(h.request(), undefined);
  }
  await h.fast();
  assert.deepEqual(JSON.parse(await readFile(h.settingsPath, "utf8")), { enabled: true });
});

test("arguments are rejected without toggling or writing settings", async () => {
  const h = harness();
  const args = ["on", "off", "status", " ON ", "invalid"];
  for (const arg of args) {
    await h.fast(arg);
    assert.equal(h.request(), undefined);
    assert.deepEqual(h.notifications.at(-1), ["Usage: /fast", "warning"]);
  }
  await assert.rejects(readFile(h.settingsPath), { code: "ENOENT" });
  await h.fast();
  const before = await stat(h.settingsPath);
  for (const arg of args) {
    await h.fast(arg);
    assert.equal(h.request().service_tier, "priority");
    assert.deepEqual(h.notifications.at(-1), ["Usage: /fast", "warning"]);
  }
  const after = await stat(h.settingsPath);
  assert.equal(after.ino, before.ino);
  assert.equal(after.mtimeMs, before.mtimeMs);
});

test("save failure warns but keeps fast mode working in the current session", async () => {
  const h = harness();
  await mkdir(dirname(h.settingsPath), { recursive: true });
  await mkdir(h.settingsPath);
  await h.fast();
  assert.equal(h.request().service_tier, "priority");
  assert.match(h.notifications.at(-2)[0], /preference not saved/);
  assert.equal(h.notifications.at(-2)[1], "warning");
  assert.deepEqual(await readdir(dirname(h.settingsPath)), ["settings.json"]);
});

test("unexpected read failures are reported", async () => {
  const h = harness();
  await mkdir(h.settingsPath, { recursive: true });
  await h.emit("session_start");
  assert.equal(h.request(), undefined);
  assert.match(h.notifications.at(-1)[0], /preference could not be loaded/);
  assert.equal(h.notifications.at(-1)[1], "warning");
});

test("clears the old footer status on reload and never adds one", async () => {
  const h = harness();
  h.statuses.set("gpt-fast", "GPT fast: on");
  await h.emit("session_start");
  assert.equal(h.statuses.get("gpt-fast"), undefined);
  h.ctx.ui.setStatus = (key, value) => {
    assert.equal(key, "gpt-fast");
    assert.equal(value, undefined);
  };
  await h.fast();
  assert.equal(h.notifications.at(-1)[0], "GPT Fast mode is on.");
  await h.fast();
  assert.equal(h.notifications.at(-1)[0], "GPT Fast mode is off.");
});

test("ignores malformed payloads and works without terminal UI", async () => {
  const h = harness();
  h.ctx.hasUI = false;
  h.ctx.ui.setStatus = () => { throw new Error("No terminal UI"); };
  await h.emit("session_start");
  await h.fast();
  for (const payload of [null, false, 42, "payload", []]) {
    assert.equal(h.request(payload), undefined);
  }
  assert.equal(h.request().service_tier, "priority");
});

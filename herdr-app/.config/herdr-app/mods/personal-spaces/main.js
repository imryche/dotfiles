// One navigation row per tab. Spaces supply context, agents supply status.
import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex, ScrollHandle } from "gpui-base";
import { agents, closeOverlay, focused, hc, layout, machines, nextCommand, openOverlay, panes, props, run, setAgentOrder, setShared, shared, spaces, terminals, theme, window } from "herdr";

const art = name => svg(`mods/workspace-chrome/${name}.svg`);
const ITEM_GAP = 3;
const LIST_INSET = 8;
const TAB_INSET = 10;
const ICON_SLOT = 19;
const STATUS_SLOT = 16;
const CHROME_ICON_SIZE = 18;
const TOOL_SIZE = 26;
const rank = { blocked: 4, done: 3, working: 2, idle: 1 };
const statusName = { blocked: "Needs you", done: "Done", working: "Working", idle: "Idle" };
const urgency = (a, b) => (rank[b] ?? 0) > (rank[a] ?? 0) ? b : a;
const statusOf = status => status === "error" ? "blocked" : status;
const addMenu = () => openOverlay({ mod: "personal-spaces", kind: "popup", width: 210, props: { newMenu: true } });

function findNode(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = findNode(child, id);
    if (found) return found;
  }
}

function tabDetails() {
  const byTab = new Map();
  const byParent = new Map();
  const liveAgents = agents();
  const addresses = new Set(liveAgents.map(a => a.address));
  const get = id => {
    if (!byTab.has(id)) byTab.set(id, { panes: [], agents: [], status: null });
    return byTab.get(id);
  };
  for (const p of panes()) get(p.tab).panes.push(p);
  for (const a of liveAgents) get(a.tab).agents.push({ ...a, depth: 0 });
  for (const terminal of terminals()) {
    if (terminal.state !== "live" || !terminal.parent || addresses.has(terminal.address)) continue;
    if (!byParent.has(terminal.parent)) byParent.set(terminal.parent, []);
    byParent.get(terminal.parent).push(terminal);
  }
  for (const data of byTab.values()) {
    function addChildren(agent) {
      data.status = urgency(data.status, agent.status);
      return [agent, ...(byParent.get(agent.address) ?? []).flatMap(child => addChildren({
        ...child, depth: agent.depth + 1, status: child.status === "done" ? "idle" : statusOf(child.status),
      }))];
    }
    data.agents = data.agents.flatMap(addChildren);
  }
  return byTab;
}

function tabRows(space, byTab) {
  const rows = [];
  const counts = new Map();
  for (const tab of [...space.tabs].sort((a, b) => a.index - b.index)) {
    const data = byTab.get(tab.id);
    const status = urgency(tab.status, data?.status);
    const active = space.active && tab.active;
    if (tab.settled && !active && status !== "blocked" && status !== "done") continue;
    const items = data?.panes ?? [];
    const lead = items.find(p => p.program?.agent) ?? items.find(p => p.focused) ?? items[0];
    const program = lead?.program;
    const title = tab.named ? tab.name : lead?.name || (program?.shell ? "Terminal" : program?.name || lead?.title || "Terminal");
    counts.set(title, (counts.get(title) ?? 0) + 1);
    rows.push({ tab, space, title, program, branch: lead?.branch ?? space.branch, status, active, agents: data?.agents ?? [] });
  }
  for (const row of rows) if (!row.tab.named && counts.get(row.title) > 1) row.title += ` ${row.tab.index}`;
  return rows;
}

function programIcon(program, t) {
  const icon = program?.icon;
  const glyph = !icon ? art("terminal").size(13) : program.tint ? svg(icon).size(13) : image(icon).size(14);
  return h_flex().size(ICON_SLOT).flex_none().rounded(5).items_center().justify_center()
    .text_color(program?.color ?? t.muted).when(Boolean(program?.tile), el => el.bg(program.tile))
    .child(glyph);
}

function indicator(status, t) {
  if (status === "working") return art("spinner").size(11).text_color(t.working).spin(900);
  if (status === "blocked") return div().size(14).rounded(4).bg(t.blocked + "26").text_color(t.blocked)
    .text_size(10).font_bold().flex().items_center().justify_center().child("!");
  if (status === "done") return div().size(6).rounded(3).bg(t.done);
  return div();
}

function trailing(element) {
  return div().w(STATUS_SLOT).flex_none().flex().items_center().justify_center().child(element);
}

function fade(id, on, color, duration) {
  return div().id(id).absolute().inset_0().bg(color)
    .opacity(on ? 1 : 0).transition("opacity", { duration, easing: "ease-out" });
}

export default class Sidebar extends View {
  init(_props, cx) {
    const p = props();
    if (p?.rowMenu || p?.newMenu) {
      this.menuIndex = 0;
      this.handle = cx.focus_handle();
      this.handle.focus();
      return;
    }
    this.hovered = new Set();
    this.machines = [];
    this.folded = new Set(JSON.parse(localStorage.getItem("machines.folded") ?? "[]"));
    this.reconnecting = JSON.parse(localStorage.getItem("machines.reconnecting") ?? "{}");
    for (const state of Object.values(this.reconnecting)) state.busy = false;
    this.scroll = ScrollHandle.new();
    this.navigation = [];
    this.refreshMachines(cx);
    cx.timer.every(15000, cx => this.refreshMachines(cx));
    cx.spawn(async () => {
      for (;;) {
        const command = await nextCommand();
        if (command === "next") this.navigate(1);
        if (command === "prev") this.navigate(-1);
      }
    });
  }

  navigate(step) {
    const rows = this.navigation;
    if (!rows.length) return;
    const active = focused()?.tab;
    const from = rows.findIndex(row => row.tab === active);
    const index = from < 0 ? (step > 0 ? 0 : rows.length - 1) : (from + step + rows.length) % rows.length;
    const target = rows[index];
    if (target.tab !== active) run("tab.select", { id: target.tab });
    this.scroll.scroll_to_item(target.index);
  }

  refreshMachines(cx) {
    cx.spawn(async cx => {
      try {
        const r = await hc(["machine", "ls", "--json"]);
        if (r.code === 0) this.machines = (JSON.parse(r.stdout).machines ?? []).filter(m => !m.temporary);
      } catch {}
      cx.notify();
    });
  }

  reconnect(machine, cx) {
    const name = machine.name;
    if (this.reconnecting[name]?.busy) return;
    const state = this.reconnecting[name] ??= { machine, removed: false };
    state.busy = true;
    state.error = null;
    localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
    cx.notify();
    cx.spawn(async cx => {
      try {
        const ask = async args => {
          const r = await hc([...args, "--json"]);
          if (r.code === 0) return;
          let error;
          try { error = JSON.parse(r.stdout || r.stderr).error?.message; } catch {}
          throw new Error(error || r.stderr || r.stdout || "Couldn't connect.");
        };
        if (!state.removed) {
          await ask(["machine", "rm", name]);
          state.removed = true;
          localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
        }
        const args = ["machine", "add", ...(machine.via ? ["--via", machine.target] : [machine.target]), "--name", name];
        if (machine.session) args.push("--session", machine.session);
        if (machine.temporary) args.push("--temp");
        await ask(args);
        this.folded.delete(name);
        localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
        delete this.reconnecting[name];
      } catch (e) {
        state.error = String(e.message ?? e);
        state.busy = false;
      }
      localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
      this.refreshMachines(cx);
      cx.notify();
    });
  }

  newMenu(p, t) {
    const space = spaces().find(s => s.active);
    const items = [
      ["terminal", "Terminal", () => run("tab.new", { space: space?.id })],
      ["plus", "New space", () => run("space.new")],
    ];
    if (space) {
      const worktree = (action, width, height) => () => openOverlay({ mod: "worktree", kind: "dialog", width, height,
        props: { space: space.id, folder: panes().find(pane => pane.focused)?.cwd, action } });
      items.push(
        ["branch", "New worktree…", worktree("new", 460, 280)],
        ["branch", "Open worktree…", worktree("open", 560, 480)],
      );
    }
    return this.menu(p, t, items);
  }

  rowMenu(p, t) {
    const group = spaces().find(s => s.id === p.space);
    const tab = group?.tabs.find(tab => tab.id === p.rowMenu);
    if (!tab) return div();
    const spaceMenu = () => openOverlay({ mod: "menu", kind: "popup", width: 200, height: 260, props: { tab: "space", target: { id: group.id } } });
    const list = tabDetails().get(tab.id)?.agents ?? [];
    const items = [
      ["square-pen", "Rename tab", () => run("tab.rename", { id: tab.id })],
      ["plus", "New tab in this space", () => run("tab.new", { space: group.id })],
      ["folder", `Space actions: ${group.name}`, spaceMenu],
      ["x", "Close tab", () => run("tab.close", { id: tab.id })],
      ...list.map(a => ["terminal", a.pane_name || a.name || a.template || a.program?.name || a.address,
        () => a.depth ? run("terminal.peek", { terminal: a.address }) : run("agent.focus", { terminal: a.address }), a]),
    ];
    return this.menu(p, t, items);
  }

  menu(p, t, items) {
    const choose = fn => { closeOverlay(p.overlay); fn(); };
    return v_flex().id("sidebar-menu").track_focus(this.handle).w_full().max_h(440).overflow_y_scrollbar().p(5).bg(t.popover)
      .on_key_down((e, cx) => {
        const delta = e.key === "up" ? -1 : e.key === "down" ? 1 : 0;
        if (!delta && e.key !== "enter") return;
        cx.stop_propagation();
        if (delta) { this.menuIndex = (this.menuIndex + delta + items.length) % items.length; cx.notify(); }
        else if (items[this.menuIndex]) choose(items[this.menuIndex][2]);
      })
      .children(items.map(([icon, label, action, agent], i) => v_flex()
        .when(i === 4 && Boolean(agent), el => el.child(div().px(8).pt(8).pb(3).text_size(11).text_color(t.dim).child("Agents in this tab")))
        .child(h_flex().id(`action-${i}`).h(30).pl(8 + Math.min(agent?.depth ?? 0, 4) * 12).pr(5).gap(7).items_center().rounded(6)
          .bg(i === this.menuIndex ? t.raised : t.popover).hover(s => s.bg(t.hover)).text_color(t.foreground).text_size(12)
          .on_click(() => choose(action))
          .child(agent ? programIcon(agent.program, t) : art(icon).size(13).flex_none().text_color(t.muted))
          .child(div().flex_1().min_w(0).truncate().child(label))
          .when(Boolean(agent), el => el.child(indicator(agent.status, t)))
          .when(agent?.depth === 0, el => el.child(div().id(`agent-pin-${agent.address}`).p(4).rounded(4).text_color(agent.pinned ? t.accent : t.dim)
            .hover(s => s.bg(t.raised).text_color(t.foreground)).tooltip(agent.pinned ? "Unpin agent" : "Pin agent")
            .on_click((_e, cx) => { cx.stop_propagation(); run("terminal.pin", { terminal: agent.address, pinned: !agent.pinned }); })
            .child(art(agent.pinned ? "pin-off" : "pin").size(12)))))));
  }

  row(row, t, collapsed, rim) {
    const { tab, space, title, program, branch, status, active } = row;
    const id = `tab-${tab.id}`;
    const hovered = this.hovered.has(id);
    const context = [title, space.name, branch && branch !== space.name && branch, statusName[status]].filter(Boolean).join("\n");
    return h_flex().id(id).relative().h(30).flex_none().rounded_full().items_center()
      .when(collapsed, el => el.justify_center().tooltip(context))
      .when(!collapsed, el => el.px(TAB_INSET).gap(7))
      .cursor_pointer()
      .on_hover((on, cx) => { on ? this.hovered.add(id) : this.hovered.delete(id); cx.notify(); })
      .on_mouse_down("left", e => {
        this.pressed = { space: space.id, tab: tab.id };
        if (e.click_count === 2) run("tab.rename", { id: tab.id });
      })
      .on_mouse_up("left", () => {
        const from = this.pressed;
        this.pressed = null;
        if (from?.space !== space.id) return;
        if (from.tab !== tab.id) run("tab.move", { id: from.tab, index: tab.index });
        else run("tab.select", { id: tab.id });
      })
      .on_mouse_down("right", () => openOverlay({ mod: "personal-spaces", kind: "popup", width: 244, props: { rowMenu: tab.id, space: space.id } }))
      .child(fade(`selected-${id}`, active, t.selected ?? t.raised, 130).rounded_full()
        .when(rim?.color && rim.width > 0, el => el.border(rim.width).border_color(t[rim.color] ?? rim.color)))
      .child(fade(`hover-${id}`, hovered, t.foreground + "0d", hovered ? 100 : 150).rounded_full())
      .child(programIcon(program, t))
      .when(!collapsed, el => el
        .child(div().flex_1().min_w(0).truncate().text_color(active || status === "blocked" ? t.foreground : t.muted).child(title))
        .child(div().min_w(0).max_w("35%").truncate().text_right().text_size(11.5).text_color(t.dim).opacity(0.88).child(space.name))
        .child(trailing(indicator(status, t))))
      .when(collapsed && status !== "idle" && Boolean(status), el => el.child(div().absolute().right(3).top(3).child(indicator(status, t))));
  }

  machineGroup(name, rows, emptySpaces, state, t, collapsed, multiMachine, rim) {
    const id = name ?? "local";
    const repair = this.reconnecting[name];
    const machine = this.machines.find(m => m.name === name) ?? repair?.machine;
    const rebuilding = repair || (machine?.state === "unreachable" && /^a different core answers there \("[^"]+"\)$/.test(machine.why ?? ""));
    const folded = this.folded.has(name);
    const loading = state === "loading" || (!state && machine?.state === "connected");
    const offline = name !== null && (state === "unavailable" || (!state && machine?.state && machine.state !== "connected"));
    const toggle = (_e, cx) => {
      folded ? this.folded.delete(name) : this.folded.add(name);
      localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
      cx.notify();
    };
    const headingId = `machine-${id}`;
    const hovered = this.hovered.has(headingId);
    const ink = el => el.text_color(t.muted).opacity(hovered ? 1 : 0.65)
      .transition("opacity", { duration: hovered ? 100 : 150, easing: "ease-out" });
    const heading = h_flex().id(headingId).h(28).flex_none().gap(7).rounded(7).items_center().text_size(13).text_color(t.dim)
      .cursor_pointer().on_click(toggle)
      .on_hover((on, cx) => { on ? this.hovered.add(headingId) : this.hovered.delete(headingId); cx.notify(); })
      .when(collapsed, el => el.justify_center())
      .when(!collapsed, el => el.pl(TAB_INSET).pr(LIST_INSET).when(!folded, heading => heading.mb(8 - ITEM_GAP)))
      .child(ink(h_flex().id(`${headingId}-icon`).w(ICON_SLOT).flex_none().items_center().justify_center())
        .child(art(name ? "server" : "monitor").size(name ? 16 : CHROME_ICON_SIZE)))
      .when(!collapsed, el => el.child(ink(div().id(`${headingId}-label`).flex_1().min_w(0).truncate().font_family("Geist").font_semibold()).child(name ?? "This computer"))
        .when(multiMachine && !loading && !offline && !rebuilding, el => el.child(div().id(`machine-add-${id}`).p(4).rounded(4)
          .hover(s => s.bg(t.raised)).tooltip(`New space on ${name ?? "this computer"}`)
          .on_click((_e, cx) => { cx.stop_propagation(); run("space.new", { machine: name ?? "" }); }).child(art("plus").size(11))))
        .when(folded, el => el.child(trailing(indicator(rows.reduce((top, row) => urgency(top, row.status), null), t)))));
    const items = [{ element: heading }];
    if (folded) return items;
    if (rebuilding && !collapsed) {
      items.push({ element: h_flex().px(8).gap(6).items_center().text_size(11.5).text_color(t.dim)
        .child(div().flex_1().truncate().child(repair?.error || "Machine replaced"))
        .child(div().id(`reconnect-${id}`).cursor_pointer().text_color(t.foreground).on_click((_e, cx) => this.reconnect(machine, cx)).child(repair?.busy ? "Connecting…" : "Connect")) });
      return items;
    }
    for (const row of rows) items.push({ element: this.row(row, t, collapsed, rim), tab: row.tab.id });
    for (const s of emptySpaces) items.push({ element:
      h_flex().id(`empty-space-${s.id}`).h(30).gap(7).items_center().rounded(12).text_color(t.muted).hover(el => el.bg(t.hover))
        .when(collapsed, el => el.justify_center()).when(!collapsed, el => el.px(TAB_INSET))
        .on_click(() => run("space.select", { id: s.id })).tooltip(s.name)
        .on_mouse_down("right", () => openOverlay({ mod: "menu", kind: "popup", width: 200, height: 260, props: { tab: "space", target: { id: s.id } } }))
        .child(h_flex().w(ICON_SLOT).flex_none().items_center().justify_center().child(art("folder").size(14)))
        .when(!collapsed, el => el.child(div().truncate().child(s.name))) });
    const note = loading ? "Loading…" : offline ? (machine?.state ?? "Offline").replace(/_/g, " ") : items.length === 1 ? "No open tabs" : null;
    if (note && !collapsed) items.push({ element: div().px(8).py(3).text_size(11.5).text_color(t.dim).child(note) });
    return items;
  }

  render() {
    const t = theme();
    const p = props();
    if (p?.newMenu) return this.newMenu(p, t);
    if (p?.rowMenu) return this.rowMenu(p, t);
    const root = layout();
    const width = findNode(root, "sidebar")?.size?.px ?? 268;
    const collapsed = width < 160;
    const rim = findNode(root, "main")?.content?.pane?.focus;
    const allSpaces = spaces();
    const states = new Map(machines().map(m => [m.name, m.layout]));
    const remote = new Set([...allSpaces.map(s => s.machine), ...this.machines.map(m => m.name), ...states.keys(), ...Object.keys(this.reconnecting)].filter(Boolean));
    const byTab = tabDetails();
    const order = [];
    const items = [];
    this.navigation = [];
    // Keep rows as direct children so the scroll handle can reveal them by index.
    for (const name of [null, ...[...remote].sort()]) {
      if (items.length) items.push(div().h(13 - 2 * ITEM_GAP).flex_none());
      const mine = allSpaces.filter(s => (s.machine ?? null) === name).sort((a, b) => a.index - b.index);
      const rows = mine.flatMap(s => tabRows(s, byTab));
      order.push(...rows.flatMap(row => row.agents.filter(a => a.depth === 0).map(a => a.address)));
      for (const { element, tab } of this.machineGroup(name, rows, mine.filter(s => !s.tabs.length), states.get(name), t, collapsed, remote.size > 0, rim)) {
        if (tab) this.navigation.push({ tab, index: items.length });
        items.push(element);
      }
    }
    setAgentOrder(order);
    const toolbar = (id, label, icon, action, iconSize = CHROME_ICON_SIZE) => {
      const hovered = this.hovered.has(id);
      return h_flex().id(id).relative().size(TOOL_SIZE).rounded(6).items_center().justify_center().cursor_pointer()
        .text_color(t.muted).hover(el => el.text_color(t.foreground)).tooltip(label).on_click(action)
        .on_hover((on, cx) => { on ? this.hovered.add(id) : this.hovered.delete(id); cx.notify(); })
        .child(fade(`hover-${id}`, hovered, t.foreground + "0d", hovered ? 100 : 150).rounded(6))
        .child(art(icon).size(iconSize));
    };
    return v_flex().id("sidebar-lists").size_full().min_h(0).bg(t.chrome).text_size(13)
      .on_mouse_up("left", () => { this.pressed = null; })
      .child(h_flex().px(collapsed ? 4 : 10).py(7).gap(2).items_center().flex_none()
        .when(collapsed, el => el.flex_col().justify_center())
        .when(!collapsed, el => el.pt(11)
          .pl(LIST_INSET + TAB_INSET + (ICON_SLOT - TOOL_SIZE) / 2)
          .pr(LIST_INSET + TAB_INSET + (STATUS_SLOT - TOOL_SIZE) / 2))
        .child(toolbar("sidebar-toggle-width", collapsed ? "Expand sidebar" : "Collapse sidebar", "sidebar", () => {
          if (!collapsed) setShared("sidebar.width", width);
          run("layout.resize", { id: "sidebar", px: collapsed ? (shared("sidebar.width") ?? 268) : window()?.platform === "macos" ? 76 : 44 });
        }))
        .when(!collapsed, el => el.child(div().flex_1()))
        .child(toolbar("sidebar-new", "New tab, space or worktree", "plus", addMenu, 15)))
      .child(v_flex().id("sidebar-scroll").flex_1().min_h(0).px(collapsed ? 3 : LIST_INSET).pb(8).gap(ITEM_GAP)
        .overflow_y_scrollbar().track_scroll(this.scroll).children(items));
  }
}

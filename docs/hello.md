# Hello: Omarchy and pi

Hello is a Solitude-derived dark theme with restrained silver window borders,
a colorful `hello` wallpaper, and red/green diff colors.

## Files

The `omarchy` Stow package contains:

- `.config/omarchy/themes/hello/`: the full local theme, including its wallpaper
  and inherited application overrides/assets.
- `.config/hypr/hyprland.lua`: the user Hyprland entrypoint, including fully opaque
  browser exceptions (Chromium/Firefox tags and Brave Origin).
- `.config/omarchy/shell.json`: personal shell/bar layout, without the Omarchy menu
  button. This references the separately installed `ryche.cellular` plugin;
  that plugin is not included in this package.
- `.config/omarchy/branding/screensaver.txt`: the centered text-art `hello`
  screensaver. Branding is desktop-wide, not theme-specific.

The existing `pi` package contains `.pi/agent/themes/hello.json`. This is a
standalone pi theme with neutral interface/panel colors and colored additions
and removals; Omarchy's generated `omarchy-system.json` is deliberately not
tracked.

## Installation

Use this on an installed Omarchy system with GNU Stow. Back up and move aside
conflicting files before stowing; do not use `--adopt` to overwrite this package
with another machine's defaults.

From a fresh checkout, with no conflicting target files:

```bash
stow --simulate --verbose --dir="$HOME/dotfiles" --target="$HOME" omarchy pi
stow --verbose --dir="$HOME/dotfiles" --target="$HOME" omarchy pi
omarchy theme set hello
hyprctl reload
hyprctl configerrors
```

Inspect the simulation first. For an existing pi installation, merge/link only
`.pi/agent/themes/hello.json` if other pi files conflict. Do not replace local
settings or unrelated configuration merely to resolve a Stow conflict.

The repository's `setup.sh` is Fedora/GNOME-oriented; do not run the full setup
script to install these Omarchy settings.

## Pi activation

In pi, run `/reload`, then select `hello` under `/settings` → Theme.

The selection is stored in `.pi/agent/settings.json`, which remains ignored by
Git. Select it locally on each machine. Once active, pi hot-reloads edits to
`~/.pi/agent/themes/hello.json`.

Pi's custom theme is independent of the terminal palette. Update it explicitly
if the desired Hello application colors change; reapplying Omarchy themes does
not regenerate this standalone pi theme.

## Current appearance

- Window borders: 1 logical px.
- Active border: `#85888C` → `#5E6165`, 90-degree gradient, alpha `e6` (~90%).
- Inactive border: `#343638`, alpha `e6` (~90%).
- Shared border tokens in `colors.toml` match `hyprland.lua`, including gradient
  direction and alpha, so generated shell borders use the same treatment.
  The legacy solid `active_border_color` token matches the lighter gradient stop.
- `shell.popups.toml` gives bar flyouts the same gradient with a 1 px outline,
  replacing their default 2 px borders.
- `shell.menu.toml` sets the menu outline to 1 px, preserving its existing colors.
  Clipboard and emoji menus share this styling.
- `shell.notifications.toml` sets notification outlines to 1 px, preserving
  their existing gradient and colors.
- Corners: rounding 8, rounding power 2.
- Gaps: inner 3, outer 6.
- Blur: enabled, size 9, passes 3 (browsers excluded).
- Shadows: range 16, render power 3, black alpha `55` active / `33` inactive.
- Regular ANSI red: `#D98080`; regular ANSI green: `#A6BE8C`.
- Bright red/green retain Solitude's original colors.
- Pi additions/removals use the regular green/red without tinting tool panels.

Edit the theme's `colors.toml` or `hyprland.lua`, then reapply:

```bash
omarchy theme set hello
hyprctl reload
hyprctl configerrors
```

Theme-specific Hyprland settings and desktop-wide browser rules have different
scopes: the browser exceptions remain active when switching away from Hello.
Changing ANSI red/green can also recolor other terminal applications; Lazygit
has not received any application-specific overrides.

## Screensaver

The text art was converted from `backgrounds/hello.png` with:

```bash
omarchy transcode ascii \
  ~/.config/omarchy/themes/hello/backgrounds/hello.png \
  /tmp/hello-screensaver.txt \
  --invert --width 100 --height 30 --threshold 15
```

The common 16-column blank left margin was then removed to center the visible
lettering. The committed `screensaver.txt` is already corrected; regenerating
it requires trimming the shared blank margin again.

Launch with `omarchy launch screensaver`. The art's shape is preserved, while
`ttfx` supplies effect colors rather than retaining the wallpaper's rainbow.

## What stays local

Do not track generated files under `~/.local/state/omarchy/current/`, generated
pi themes, settings, caches, timestamped backups, or temporary previews. The
active configuration paths link back to this repository, so future edits to
those paths update these sources directly.

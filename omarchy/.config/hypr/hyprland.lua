-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Muted, sanded-glass blur for translucent windows and the glassy bar.
hl.config({
  decoration = {
    blur = {
      size = 12,
      passes = 6,
      brightness = 0.6,
      noise = 0.03,
      vibrancy = 0.0,
    },
  },
})

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Keep browsers opaque, including Brave Origin (not tagged by stock rules).
for _, browser_tag in ipairs({ "chromium-based-browser", "firefox-based-browser" }) do
  o.window({ tag = browser_tag }, {
    opacity = "1 override 1 override 1 override",
    no_blur = true,
  })
end
o.window({ class = "^brave-origin$" }, {
  opacity = "1 override 1 override 1 override",
  no_blur = true,
})

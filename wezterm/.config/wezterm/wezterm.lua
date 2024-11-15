local wezterm = require("wezterm")

return {
  front_end = "WebGpu",
  enable_tab_bar = false,
  window_decorations = "RESIZE",
  font = wezterm.font("JetBrains Mono", { weight = "Medium" }),
  harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
  font_size = 10.0,
  color_scheme = "zenbones_dark",
}

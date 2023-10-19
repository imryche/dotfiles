local wezterm = require("wezterm")

return {
  front_end = "WebGpu",
  enable_tab_bar = false,
  font = wezterm.font("JetBrains Mono", { weight = "Medium" }),
  harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
  font_size = 11.0,
  color_scheme = "iceberg-dark",
  disable_default_key_bindings = true,
}

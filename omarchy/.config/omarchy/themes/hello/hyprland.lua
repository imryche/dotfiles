local active_border_color = { colors = { "rgba(85888ce6)", "rgba(5e6165e6)" }, angle = 90 }
local inactive_border_color = "rgba(343638e6)"

hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 6,
    border_size = 1,
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
  decoration = {
    rounding = 8,
    rounding_power = 2,
    blur = {
      enabled = true,
      size = 9,
      passes = 3,
    },
    shadow = {
      enabled = true,
      range = 16,
      render_power = 3,
      color = "rgba(00000055)",
      color_inactive = "rgba(00000033)",
    },
  },
})

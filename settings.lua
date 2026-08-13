data:extend{
  {
    type = "double-setting",
    setting_type = "runtime-global",
    name = "tomwub-pipe-opacity",
    minimum_value = 0,
    maximum_value = 1,
    default_value = 0.7
  },
  {
    type = "bool-setting",
    setting_type = "startup",
    name = "npt-tomwub-weaving",
    default_value = false,
    forced_value = false,
    hidden = not mods["no-pipe-touching"] or not not mods["color-coded-pipes"]
  },
  {
    type = "int-setting",
    name = "tomwub-underground-indicators-range",
    setting_type = "runtime-per-user",
    default_value = 50,
    maximum_value = 250,
    minimum_value = 1
  },
  {
    type = "int-setting",
    name = "tomwub-ticks-per-scan",
    setting_type = "runtime-global",
    default_value = 181,
    minimum_value = 1
  },
  {
    type = "int-setting",
    name = "tomwub-ticks-per-update",
    setting_type = "runtime-global",
    default_value = 251,
    minimum_value = 1
  },
  {
    type = "int-setting",
    name = "tomwub-min-registrations-per-tick",
    setting_type = "runtime-global",
    default_value = 12,
    minimum_value = 1
  },
  {
    type = "int-setting",
    name = "tomwub-checks-per-update",
    setting_type = "runtime-global",
    default_value = 4,
    minimum_value = 1
  },
  {
    type = "string-setting",
    name = "tomwub-migration-mode",
    setting_type = "runtime-global",
    allowed_values = {
      "off",
      "safe",
      "unsafe"
    },
    default_value = "safe"
  }
}
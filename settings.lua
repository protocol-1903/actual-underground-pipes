data:extend{
  {
    type = "double-setting",
    name = "tomwub-pipe-opacity",
    setting_type = "runtime-global",
    minimum_value = 0,
    maximum_value = 1,
    default_value = 0.7
  },
  {
    type = "bool-setting",
    name = "npt-tomwub-weaving",
    setting_type = "startup",
    default_value = false
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
  },
  {
    type = "bool-setting",
    name = "tomwub-tint-pipes-by-fluid",
    setting_type = "runtime-global",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "tomwub-always-show-undergrounds",
    setting_type = "runtime-global",
    default_value = false
  }
}
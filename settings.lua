data:extend{
  {
    type = "double-setting",
    setting_type = "runtime-global",
    name = "pipe-opacity",
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
  }
}
data:extend{
  {
    type = "double-setting",
    setting_type = "startup",
    name = "pipe-opacity",
    minimum_value = 0,
    maximum_value = 1,
    default_value = 0.2
  }
}

if mods["FluidMustFlow"] then
  data:extend{{
    type = "double-setting",
    setting_type = "startup",
    name = "fmf-pipe-opacity",
    minimum_value = 0,
    maximum_value = 1,
    default_value = 0.25
  }}
end
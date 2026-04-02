require "util"

data:extend{{
  type = "custom-input",
  name = "tomwub-swap-layer",
  key_sequence = "G",
  linked_game_control = "toggle-rail-layer",
  action = "lua"
}}

-- only create a generic collision mask when weaving is not enabled
if not settings.startup["npt-tomwub-weaving"].value then
  data:extend{{
    type = "collision-layer",
    name = "tomwub-underground"
  }}
end

for bitmask, filename in pairs{
  [0] = "pipe-straight-vertical-single",
  "pipe-ending-up",
  "pipe-ending-right",
  "pipe-corner-up-right",
  "pipe-ending-down",
  "pipe-straight-vertical",
  "pipe-corner-down-right",
  "pipe-t-right",
  "pipe-ending-left",
  "pipe-corner-up-left",
  "pipe-straight-horizontal",
  "pipe-t-up",
  "pipe-corner-down-left",
  "pipe-t-left",
  "pipe-t-down",
  "pipe-cross",
} do
  data:extend{{
    type = "sprite",
    name = ("tomwub-indicator-%02d"):format(bitmask),
    filename = ("__the-one-mod-with-underground-bits__/graphics/indicators/%s.png"):format(filename),
    size = 128,
    scale = 0.5,
    shift = util.by_pixel(0, tomwub.downshift)
  }}
end
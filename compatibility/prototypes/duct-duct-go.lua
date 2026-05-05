if not mods["duct-duct-go"] then return end

data.raw.recipe["duct-underground"].ingredients[1].amount = 16
data.raw.pipe["tomwub-duct"].radius_visualisation_specification = {
  sprite = {
    filename = "__the-one-mod-with-underground-bits__/graphics/duct-placement-indicator.png",
    size = 256,
    scale = 0.5
  },
  offset = util.by_pixel(0, tomwub.downshift),
  distance = 2
}

for bitmask, picture in pairs{
  [0] = "straight_vertical_single",
  "ending_up",
  "ending_right",
  "corner_up_right",
  "ending_down",
  "straight_vertical",
  "corner_down_right",
  "t_right",
  "ending_left",
  "corner_up_left",
  "straight_horizontal",
  "t_up",
  "corner_down_left",
  "t_left",
  "t_down",
  "cross"
} do
  local shift = data.raw.pipe.duct.pictures[picture].layers[1].shift or {0, 0}
  data:extend{{
    type = "sprite",
    name = ("tomwub-duct-indicator-%02d"):format(bitmask),
    filename = data.raw.pipe.duct.pictures[picture].layers[1].filename,
    width = data.raw.pipe.duct.pictures[picture].layers[1].width,
    height = data.raw.pipe.duct.pictures[picture].layers[1].height,
    scale = 0.5,
    shift = {shift[1], shift[2] + tomwub.downshift / 32}
  }}
end

-- since we arent crafting the underground bits anymore
data.raw.recipe["duct-underground"].ingredients[1].amount = 16
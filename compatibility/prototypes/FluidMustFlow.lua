if not mods["FluidMustFlow"] or mods["duct-duct-go"] then return end

local underground = data.raw["pipe-to-ground"]["duct-underground"]
local mask, layer, connection_category = tomwub.adjust_ptg(underground, "duct")
underground.heating_energy = data.raw["storage-tank"]["duct-small"].heating_energy

for i, t in pairs{
  "duct-curve",
  "duct-t-junction",
  "duct-cross",
  "duct",
  "duct-small",
  "duct-long"
} do
  local tank = data.raw["storage-tank"][t]
  if tank and not tank.ignore_by_tomwub then
    local u_tank = tomwub.make_tomwub_variant(tank, mask, layer, connection_category)
    u_tank.placeable_by = { {item = "tomwub-pipe", count = 1}, {item = "pipe", count = 1}, {item = "tomwub-" .. t, count = 1}, {item = t, count = 1} }
    tomwub.reformat(u_tank.pictures.picture)
    if settings.startup["fmf-enable-duct-auto-join"].value and i > 3 then
      u_tank.placeable_by = {
        {item = "tomwub-duct-small", count = t == "duct" and 2 or t == "duct-small" and 1 or 4},
        {item = "duct-small", count = t == "duct" and 2 or t == "duct-small" and 1 or 4}
      }
    end
    local bitmasks = {north = 0, east = 0, south = 0, west = 0}
    for _, pipe_connection in pairs(tank.fluid_box.pipe_connections) do
      bitmasks.north = bitmasks.north + 2 ^ ((pipe_connection.direction / 4) % 4)
      bitmasks.east = bitmasks.east + 2 ^ ((pipe_connection.direction / 4 + 1) % 4)
      bitmasks.south = bitmasks.south + 2 ^ ((pipe_connection.direction / 4 + 2) % 4)
      bitmasks.west = bitmasks.west + 2 ^ ((pipe_connection.direction / 4 + 3) % 4)
    end
    for direction, bitmask in pairs(bitmasks) do
      data:extend{{
        type = "sprite",
        name = ("tomwub-%s-indicator-%02d"):format(t, bitmask),
        filename = tank.pictures.picture[direction].layers[1].filename,
        height = tank.pictures.picture[direction].layers[1].height,
        width = tank.pictures.picture[direction].layers[1].width,
        scale = 0.5,
        shift = util.by_pixel(0, tomwub.downshift)
      }}
    end
  end
end

-- since we arent crafting the underground bits anymore
data.raw.recipe["duct-underground"].ingredients[1].amount = 16
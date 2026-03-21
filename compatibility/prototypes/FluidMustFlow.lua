if not mods["FluidMustFlow"] then return end

local underground = data.raw["pipe-to-ground"]["duct-underground"]
local mask, layer, connection_category = tomwub.adjust_ptg(underground, "duct")
underground.heating_energy = data.raw["storage-tank"].duct.heating_energy

for i, t in pairs{
  "duct-curve",
  "duct-t-junction",
  "duct-cross",
  "duct",
  "duct-small",
  "duct-long"
} do
  local tank = data.raw["storage-tank"][t]
  if tank then
    local u_tank = tomwub.make_tomwub_variant(tank, mask, layer, connection_category)
    u_tank.placeable_by = { {item = "tomwub-pipe", count = 1}, {item = "pipe", count = 1}, {item = "tomwub-" .. t, count = 1}, {item = t, count = 1} }
    tomwub.reformat(u_tank.pictures.picture)
    if settings.startup["fmf-enable-duct-auto-join"].value and i > 3 then
      u_tank.placeable_by = {
        {item = "tomwub-duct-small", count = t == "duct" and 2 or t == "duct-small" and 1 or 4},
        {item = "duct-small", count = t == "duct" and 2 or t == "duct-small" and 1 or 4}
      }
    end
  end
end

-- since we arent crafting the underground bits anymore
data.raw.recipe["duct-underground"].ingredients[1].amount = 16
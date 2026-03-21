if not mods["Flow Control"] then return end

for _, t in pairs{
  "pipe-elbow",
  "pipe-junction",
  "pipe-straight"
} do
  local tank = data.raw["storage-tank"][t]
  if tank then
    local u_tank = tomwub.make_tomwub_variant(tank, data.raw.pipe["tomwub-pipe"].collision_mask)
    u_tank.placeable_by = { {item = "tomwub-pipe", count = 1}, {item = "pipe", count = 1}, {item = "tomwub-" .. t, count = 1}, {item = t, count = 1} }
    tomwub.reformat(u_tank.pictures.picture)
    u_tank.fluid_box.pipe_covers = u_tank.fluid_box.pipe_covers or table.deepcopy(pipecoverspictures())
    tomwub.reformat(u_tank.fluid_box.pipe_covers)
  end
end
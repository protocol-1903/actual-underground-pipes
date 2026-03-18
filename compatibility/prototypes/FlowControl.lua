if not mods["Flow Control"] then return end

for _, t in pairs{
  "pipe-elbow",
  "pipe-junction",
  "pipe-straight"
} do
  local u_tank = xutil.make_tomwub_variant(data.raw["storage-tank"][t], data.raw.pipe["tomwub-pipe"].collision_mask)
  u_tank.placeable_by = { {item = "tomwub-pipe", count = 1}, {item = "pipe", count = 1}, {item = "tomwub-" .. t, count = 1}, {item = t, count = 1} }
  xutil.reformat(u_tank.pictures.picture)
  u_tank.fluid_box.pipe_covers = u_tank.fluid_box.pipe_covers or table.deepcopy(pipecoverspictures())
  xutil.reformat(u_tank.fluid_box.pipe_covers)
end
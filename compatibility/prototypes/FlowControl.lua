if not mods["Flow Control"] then return end

local xutil = require "__the-one-mod-with-underground-bits__.util"

local pipes = {
  "pipe-elbow",
  "pipe-junction",
  "pipe-straight"
}

local underground_collision_mask = data.raw["pipe-to-ground"]["pipe-to-ground"].fluid_box.pipe_connections[2].underground_collision_mask or {layers = {}}
local tag = data.raw["pipe-to-ground"]["pipe-to-ground"].fluid_box.pipe_connections[2].connection_category

-- they can only be placed inside the map
underground_collision_mask.layers["out_of_map"] = true

-- solve the underground pipes
for _, pipe in pairs(pipes) do
  local p = pipe
  local pipe = data.raw["storage-tank"][p]
  -- create new item, entity, and collision layer
  data.extend{
    {
      type = "item",
      name = "tomwub-" .. p,
      icon = pipe.icon or data.raw.pipe.pipe.icon,
      icon_size = pipe.icon_size or data.raw.pipe.pipe.icon_size,
      place_result = "tomwub-" .. p,
      flags = {"only-in-cursor"},
      stack_size = data.raw.item[p].stack_size
    },
    {
      type = "storage-tank",
      name = "tomwub-" .. p,
      icon = pipe.icon or data.raw.pipe.pipe.icon,
      icon_size = pipe.icon_size or data.raw.pipe.pipe.icon_size,
      localised_name = {"entity-name.tomwub-underground", pipe.localised_name or {"entity-name." .. pipe.name}},
      fluid_box = table.deepcopy(pipe.fluid_box),
      pictures = table.deepcopy(pipe.pictures),
      collision_box = pipe.collision_box,
      selection_box = pipe.selection_box,
      collision_mask = underground_collision_mask or { layers = {} },
      flags = {"not-upgradable", "player-creation", "placeable-neutral"},
      window_bounding_box = pipe.window_bounding_box,
      flow_length_in_ticks = pipe.flow_length_in_ticks,
      icon_draw_specification = table.deepcopy(pipe.icon_draw_specification),
      minable = pipe.minable,
      selection_priority = 255,
      placeable_by = { {item = "tomwub-pipe", count = 1}, {item = "pipe", count = 1}, {item = "tomwub-" .. p, count = 1}, {item = p, count = 1} },
      is_military_target = false
    }
  }
  tomwub_pipe = data.raw["storage-tank"]["tomwub-" .. p]
  for _, pipe_connection in pairs(tomwub_pipe.fluid_box.pipe_connections) do
    pipe_connection.connection_category = tag
  end

  -- set the collision mask to the connection_category collected earlier
  tomwub_pipe.collision_mask.layers[tag] = true

  -- shift everything down
  xutil.reformat(tomwub_pipe.fluid_box.pipe_covers)
  if tomwub_pipe.icon_draw_specification then
    tomwub_pipe.icon_draw_specification.shift = util.by_pixel(0, xutil.downshift)
    tomwub_pipe.icon_draw_specification.scale = 0.35
  end
  xutil.reformat(tomwub_pipe.pictures.picture)

  tomwub_pipe.pictures.gas_flow = nil
  tomwub_pipe.pictures.low_temperature_flow = nil
  tomwub_pipe.pictures.middle_temperature_flow = nil
  tomwub_pipe.pictures.high_temperature_flow = nil

  -- scale down the fluid icon
  tomwub_pipe.icon_draw_specification.scale = 0.35
end
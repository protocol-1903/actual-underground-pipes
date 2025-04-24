if not mods["FluidMustFlow"] then return end

local downshift = require("__the-one-mod-with-underground-bits__.util").downshift
local pipes = {
  "duct-curve",
  "duct-t-junction",
  "duct-cross",
  "duct",
  "duct-small",
  "duct-long",
}

local function reformat(spritesheet, ignore)
  for s, sprite in pairs(spritesheet) do
    if sprite.layers then
      for i, sprit in pairs(sprite.layers) do
        sprit.shift = util.by_pixel(0, downshift)
        if not s:find("visualization") then
          sprit.tint = {
            settings.startup["fmf-pipe-opacity"].value,
            settings.startup["fmf-pipe-opacity"].value,
            settings.startup["fmf-pipe-opacity"].value,
            settings.startup["fmf-pipe-opacity"].value
          }
        end
        if sprit.filename:sub(-10) == "shadow.png" then
          sprite.layers[i] = nil
        end
      end
    else
      sprite.shift = util.by_pixel(0, downshift)
      if not s:find("visualization") then
        sprite.tint = {
          settings.startup["fmf-pipe-opacity"].value,
          settings.startup["fmf-pipe-opacity"].value,
          settings.startup["fmf-pipe-opacity"].value,
          settings.startup["fmf-pipe-opacity"].value
        }
      end
    end
    if s:find("disabled_visualization") then
      sprite.filename = "__the-one-mod-with-underground-bits__/graphics/underground-disabled-visualization.png"
    elseif s:find("visualization") then
      sprite.filename = "__the-one-mod-with-underground-bits__/graphics/underground-visualization.png"
    end
  end
end

-- solve the duct to ground
local underground = data.raw["pipe-to-ground"]["duct-underground"]

underground.solved_by_tomwub = true
local underground_collision_mask, tag
-- the underground name matches with the pipe name
-- also only runs this chunk of code once per supported underground
for _, pipe_connection in pairs(underground.fluid_box.pipe_connections) do
  if pipe_connection.connection_type == "underground" then
    -- make the underground a fake underground
    pipe_connection.connection_type = "normal"
    pipe_connection.max_underground_distance = nil
    -- set the filter to the psuedo underground pipe name
    if not mods["no-pipe-touching"] then
      pipe_connection.connection_category = "tomwub-underground"
    elseif not underground.npt_compat then
      pipe_connection.connection_category = "tomwub-duct-underground"
    elseif underground.npt_compat.tag then
      pipe_connection.connection_category = "tomwub-" .. underground.npt_compat.mod .. "-" .. underground.npt_compat.tag .. "-underground"
    elseif underground.npt_compat.override then
      pipe_connection.connection_category = "tomwub-" .. underground.npt_compat.override .. "-underground"
    end
    -- save collision mask for later
    underground_collision_mask = pipe_connection.underground_collision_mask or {layers = {}}
    tag = pipe_connection.connection_category
  end
end

-- they can only be placed inside the map
underground_collision_mask.layers["out_of_map"] = true

-- set heating enrergy of pipe-to-ground to that of the pipe
underground.heating_energy = data.raw["storage-tank"].duct.heating_energy

-- update collision mask
if not underground.collision_mask then
  underground.collision_mask = {
    layers = {
      is_lower_object = true,
      water_tile = true,
      floor = true,
      transport_belt = true,
      item = true,
      car = true,
      meltable = true
    }
  }
end

-- set the collision mask to the connection_category collected earlier
underground.collision_mask.layers[tag] = true

if mods["no-pipe-touching"] then
  data.extend{{
    type = "collision-layer",
    name = tag
  }}
end

-- if recipe exists
-- if not mods["bztin"] and data.raw.recipe["duct-underground"] then
--   local ingredients = data.raw.recipe["duct-underground"].ingredients
--   data.raw.recipe["duct-underground"].ingredients = {}
--   -- add ingredient if not the associated pipe
--   for _, ingredient in pairs(ingredients) do
--     if not data.raw.pipe[ingredient.name] then -- if not a pipe then add to ingredients
--       data.raw.recipe["duct-underground"].ingredients[#data.raw.recipe["duct-underground"].ingredients+1] = ingredient
--     end
--   end
-- elseif mods["bztin"] and data.raw.recipe["duct-underground"] then
--   -- modify counts
--   for _, ingredient in pairs(data.raw.recipe["duct-underground"].ingredients) do
--     if data.raw.pipe[ingredient.name] and ingredient.amount > 2 then
--       ingredient.amount = 2 -- if a pipe, set amount to 2
--     end
--   end
-- end

-- solve the underground ducts
for i, pipe in pairs(pipes) do
  local p = pipe
  local pipe = data.raw["storage-tank"][p]
  -- create new item, entity, and collision layer
  if data.raw.item[p] then
    data:extend{{
      type = "item",
      name = "tomwub-" .. p,
      icon = pipe.icon or data.raw.pipe.pipe.icon,
      icon_size = pipe.icon_size or data.raw.pipe.pipe.icon_size,
      place_result = "tomwub-" .. p,
      flags = {"only-in-cursor"},
      stack_size = data.raw.item[p].stack_size
    }}
  end
  data.extend{
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
      placeable_by = { {item = "tomwub-" .. p, count = 1}, {item = p, count = 1} },
      is_military_target = false
    }
  }
  
  tomwub_pipe = data.raw["storage-tank"]["tomwub-" .. p]
  if settings.startup["fmf-enable-duct-auto-join"].value and i > 3 then
    tomwub_pipe.placeable_by = {
      {item = "tomwub-duct-small", count = p == "duct" and 2 or p == "duct-small" and 1 or 4},
      {item = "duct-small", count = p == "duct" and 2 or p == "duct-small" and 1 or 4}
    }
  end

  for _, pipe_connection in pairs(tomwub_pipe.fluid_box.pipe_connections) do
    pipe_connection.connection_category = tag
  end

  -- set the collision mask to the connection_category collected earlier
  tomwub_pipe.collision_mask.layers[tag] = true

  -- shift everything down
  if tomwub_pipe.icon_draw_specification then
    tomwub_pipe.icon_draw_specification.shift = util.by_pixel(0, downshift)
    tomwub_pipe.icon_draw_specification.scale = 0.35
  end
  reformat(tomwub_pipe.pictures.picture)

  tomwub_pipe.pictures.gas_flow = nil
  tomwub_pipe.pictures.low_temperature_flow = nil
  tomwub_pipe.pictures.middle_temperature_flow = nil
  tomwub_pipe.pictures.high_temperature_flow = nil

  -- update the selection box of the pipe
  tomwub_pipe.selection_box = {{tomwub_pipe.selection_box[1][1] * 0.8, tomwub_pipe.selection_box[1][2] * 0.8}, {tomwub_pipe.selection_box[2][1] * 0.8, tomwub_pipe.selection_box[2][2] * 0.8}}

end
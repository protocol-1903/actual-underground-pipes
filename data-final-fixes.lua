local xutil = require "util"

local tags = {}

for p, pipe in pairs(data.raw.pipe) do
  for u, underground in pairs(data.raw["pipe-to-ground"]) do
    if u:sub(1,-11) == p then
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
            pipe_connection.connection_category = "tomwub-" .. p .. "-underground"
          elseif underground.npt_compat.tag then
            pipe_connection.connection_category = "tomwub-" .. underground.npt_compat.mod .. "-" .. underground.npt_compat.tag .. "-underground"
          elseif underground.npt_compat.override then
            pipe_connection.connection_category = "tomwub-" .. underground.npt_compat.override .. "-underground"
          end
          -- save collision mask for later
          underground_collision_mask = pipe_connection.underground_collision_mask
          tag = pipe_connection.connection_category
        end
      end

      -- create new visualizations for the pipe-to-ground
      local old_visualization = underground.visualization or data.raw["pipe-to-ground"]["pipe-to-ground"].visualization
      log("solving visualizations")
      underground.visualization = {
        north = {layers = {table.deepcopy(old_visualization.south), old_visualization.north}},
        east = {layers = {table.deepcopy(old_visualization.west), old_visualization.east}},
        south = {layers = {table.deepcopy(old_visualization.north), old_visualization.south}},
        west = {layers = {table.deepcopy(old_visualization.east), old_visualization.west}}
      }
      underground.visualization.north.layers[1].shift = util.by_pixel(0, xutil.downshift)
      underground.visualization.east.layers[1].shift = util.by_pixel(0, xutil.downshift)
      underground.visualization.south.layers[1].shift = util.by_pixel(0, xutil.downshift)
      underground.visualization.west.layers[1].shift = util.by_pixel(0, xutil.downshift)

      -- set heating enrergy of pipe-to-ground to that of the pipe
      underground.heating_energy = pipe.heating_energy

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

      -- save the tag for later use with assembling machines
      tags[#tags+1] = tag

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
          type = "pipe",
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
          horizontal_window_bounding_box = {{0,0},{0,0}},
          vertical_window_bounding_box = {{0,0},{0,0}},
          icon_draw_specification = table.deepcopy(pipe.icon_draw_specification or data.raw.pipe.pipe.icon_draw_specification),
          minable = pipe.minable,
          selection_priority = 255,
          placeable_by = { {item = "tomwub-" .. p, count = 1}, {item = p, count = 1} },
          is_military_target = false
        }
      }
      if mods["no-pipe-touching"] then
        data.extend{{
          type = "collision-layer",
          name = tag
        }}
      end
      tomwub_pipe = data.raw.pipe["tomwub-" .. p]
      for _, pipe_connection in pairs(tomwub_pipe.fluid_box.pipe_connections) do
        pipe_connection.connection_category = tag
      end

      -- set the collision mask to the connection_category collected earlier
      tomwub_pipe.collision_mask.layers[tag] = true

      -- shift everything down
      tomwub_pipe.icon_draw_specification.shift = util.by_pixel(0, xutil.downshift)
      xutil.reformat(tomwub_pipe.pictures)
      if tomwub_pipe.fluid_box.pipe_covers == nil then
        tomwub_pipe.fluid_box.pipe_covers = table.deepcopy(pipecoverspictures())
      end
      xutil.reformat(tomwub_pipe.fluid_box.pipe_covers)

      tomwub_pipe.pictures.gas_flow = nil
      tomwub_pipe.pictures.low_temperature_flow = nil
      tomwub_pipe.pictures.middle_temperature_flow = nil
      tomwub_pipe.pictures.high_temperature_flow = nil

      -- scale down the fluid icon
      tomwub_pipe.icon_draw_specification.scale = 0.35

      -- add placement visualization
      tomwub_pipe.radius_visualisation_specification = {
        sprite = {
          filename = "__the-one-mod-with-underground-bits__/graphics/placement-visualization.png",
          size = {160, 160}
        },
        offset = util.by_pixel(0, xutil.downshift),
        distance = 0.65
      }

      -- update the selection box of the pipe
      tomwub_pipe.selection_box = {{-0.4, -0.4 + util.by_pixel(0, xutil.downshift)[2]}, {0.4, 0.4 + util.by_pixel(0, xutil.downshift)[2]}}
    
      -- if recipe exists
      if not mods["bztin"] and data.raw.recipe[u] then
        local ingredients = data.raw.recipe[u].ingredients
        data.raw.recipe[u].ingredients = {}
        -- add ingredient if not the associated pipe
        for _, ingredient in pairs(ingredients) do
          if not data.raw.pipe[ingredient.name] then -- if not a pipe then add to ingredients
            data.raw.recipe[u].ingredients[#data.raw.recipe[u].ingredients+1] = ingredient
          end
        end
      elseif mods["bztin"] and data.raw.recipe[u] then
        -- modify counts
        for _, ingredient in pairs(data.raw.recipe[u].ingredients) do
          if data.raw.pipe[ingredient.name] and ingredient.amount > 2 then
            ingredient.amount = 2 -- if a pipe, set amount to 2
          end
        end
      end
    end
  end
end

require("__the-one-mod-with-underground-bits__/compatibility/prototypes/FluidMustFlow")
require("__the-one-mod-with-underground-bits__/compatibility/prototypes/FlowControl")

data:extend{
  {
    type = "custom-input",
    name = "tomwub-swap-layer",
    key_sequence = "G",
    action = "lua"
  },
  -- {
  --   type = "custom-input",
  --   name = "tomwub-alt-mode",
  --   key_sequence = "ALT + V",
  --   action = "lua"
  -- },
  {
    type = "collision-layer",
    name = "tomwub-underground",
  }
}

local stripped_ptg_vis = data.raw["pipe-to-ground"]["pipe-to-ground"].visualization
for d, direction in pairs(stripped_ptg_vis) do
  stripped_ptg_vis[d] = direction.layers[2]
end

for u, underground in pairs(data.raw["pipe-to-ground"]) do
  if not underground.solved_by_tomwub then
    local directions, tag = {}
    for _, pipe_connection in pairs(underground.fluid_box.pipe_connections) do
      if pipe_connection.connection_type == "underground" then
        -- make the underground a fake underground
        pipe_connection.connection_type = "normal"
        pipe_connection.max_underground_distance = nil
        -- set the filter to the psuedo underground pipe name
        if not mods["no-pipe-touching"] then
          pipe_connection.connection_category = "tomwub-underground"
        elseif not underground.npt_compat then
          pipe_connection.connection_category = "tomwub-" .. "pipe" .. "-underground"
        elseif underground.npt_compat.tag then
          pipe_connection.connection_category = "tomwub-" .. underground.npt_compat.mod .. "-" .. underground.npt_compat.tag .. "-underground"
        elseif underground.npt_compat.override then
          pipe_connection.connection_category = "tomwub-" .. underground.npt_compat.override .. "-underground"
        end
        
        tag = pipe_connection.connection_category
        directions[#directions+1] = pipe_connection.direction
      end
    end

    for d, direction in pairs(directions) do
      local old_visualization = underground.visualization or stripped_ptg_vis
      underground.visualization = {}
      for i=0,3 do
        -- increment new direction from offset vector
        local vis_dir = (direction + i * 4) % 16
        -- add to base sprite
        underground.visualization[i == 0 and "north" or i == 1 and "east" or i == 2 and "south" or i == 3 and "west"] = {
          layers = {table.deepcopy(stripped_ptg_vis[vis_dir == 0 and "north" or vis_dir == 4 and "east" or vis_dir == 8 and "south" or vis_dir == 12 and "west"])}
        }
      end

      -- shift them all down
      underground.visualization.north.layers[1].shift = util.by_pixel(0, xutil.downshift)
      underground.visualization.east.layers[1].shift = util.by_pixel(0, xutil.downshift)
      underground.visualization.south.layers[1].shift = util.by_pixel(0, xutil.downshift)
      underground.visualization.west.layers[1].shift = util.by_pixel(0, xutil.downshift)

        -- copy old visualisations on top of new ones
      if old_visualization.north.layers then
        -- layers exist, copy those
        for s, sprite in pairs(old_visualization.north.layers) do
          underground.visualization.north.layers[#underground.visualization.north.layers+1] = sprite
        end
        for s, sprite in pairs(old_visualization.east.layers) do
          underground.visualization.east.layers[#underground.visualization.east.layers+1] = sprite
        end
        for s, sprite in pairs(old_visualization.south.layers) do
          underground.visualization.south.layers[#underground.visualization.south.layers+1] = sprite
        end
        for s, sprite in pairs(old_visualization.west.layers) do
          underground.visualization.west.layers[#underground.visualization.west.layers+1] = sprite
        end
      else
        -- layers do not exist, copy new ones
        underground.visualization.north.layers[#underground.visualization.north.layers+1] = old_visualization.north
        underground.visualization.east.layers[#underground.visualization.east.layers+1] = old_visualization.east
        underground.visualization.south.layers[#underground.visualization.south.layers+1] = old_visualization.south
        underground.visualization.west.layers[#underground.visualization.west.layers+1] = old_visualization.west
      end
    end

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
    underground.collision_mask.layers[tag] = true
    
    -- if recipe exists
    if data.raw.recipe[u] then
      local ingredients = data.raw.recipe[u].ingredients
      data.raw.recipe[u].ingredients = {}
      -- add ingredient if not the associated pipe
      for _, ingredient in pairs(ingredients) do
        if not ingredient.name:find("pipe") then
          data.raw.recipe[u].ingredients[#data.raw.recipe[u].ingredients+1] = ingredient
        end
      end
    end
  else
    underground.solved_by_tomwub = nil
  end
  if mods["no-pipe-touching"] then
    underground.solved_by_npt = nil
    underground.npt_compat = nil
  end
end

for _, type in pairs{
  "pump",
  "storage-tank",
  "assembling-machine",
  "furnace",
  "boiler",
  "fluid-turret",
  "mining-drill",
  "offshore-pump",
  "generator",
  "fusion-generator",
  "fusion-reactor",
  "thruster",
  "inserter",
  "agricultural-tower",
  "lab",
  "radar",
  "reactor",
  "loader",
  "infinity-pipe"
 } do
  for _, prototype in pairs(data.raw[type] or {}) do
    local fluid_boxes = {}
    -- multiple fluid_boxes
    for _, fluid_box in pairs(prototype.fluid_boxes or {}) do
      fluid_boxes[#fluid_boxes + 1] = fluid_box
    end
    -- single fluid_box
    if prototype.fluid_box then fluid_boxes[#fluid_boxes + 1] = prototype.fluid_box end
    -- input fluid_box
    if prototype.input_fluid_box then fluid_boxes[#fluid_boxes + 1] = prototype.input_fluid_box end
    -- output fluid_box
    if prototype.output_fluid_box then fluid_boxes[#fluid_boxes + 1] = prototype.output_fluid_box end
    -- fuel fluid_box
    if prototype.fuel_fluid_box then fluid_boxes[#fluid_boxes + 1] = prototype.fuel_fluid_box end
    -- oxidizer fluid_box
    if prototype.oxidizer_fluid_box then fluid_boxes[#fluid_boxes + 1] = prototype.oxidizer_fluid_box end
    -- energy source fluid_box
    if prototype.energy_source and prototype.energy_source.type == "fluid" then fluid_boxes[#fluid_boxes + 1] = prototype.energy_source.fluid_box end

    -- change!
    for f, fluid_box in pairs(fluid_boxes) do
      if fluid_box then
        for _, pipe_connection in pairs(fluid_box.pipe_connections or {}) do
          if pipe_connection.connection_type == "underground" then
            pipe_connection.connection_type = "normal"
            pipe_connection.connection_category = tags
            pipe_connection.max_underground_distance = nil
          end
        end
      end
    end
  end
end
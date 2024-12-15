local downshift = 10

local function reformat(spritesheet, ignore)
  for s, sprite in pairs(spritesheet) do
    if sprite.layers then
      for _, sprit in pairs(sprite.layers) do
        sprit.shift = util.by_pixel(0, downshift)
        if not s:find("visualization") then
          sprit.tint = {0,0,0,0}
        end
      end
    else
      sprite.shift = util.by_pixel(0, downshift)
      if not s:find("visualization") then
        sprite.tint = {0,0,0,0}
      end
    end
    if s:find("disabled_visualization") then
      sprite.filename = "__the-one-mod-with-underground-bits__/graphics/underground-disabled-visualization.png"
    elseif s:find("visualization") then
      sprite.filename = "__the-one-mod-with-underground-bits__/graphics/underground-visualization.png"
    end
  end
end

for p, pipe in pairs(data.raw.pipe) do
  for u, underground in pairs(data.raw["pipe-to-ground"]) do
    if u:sub(1,-11) == p then
      local underground_collision_mask
      -- the underground name matches with the pipe name
      -- also only runs this chunk of code once per supported underground
      for _, pipe_connection in pairs(underground.fluid_box.pipe_connections) do
        if pipe_connection.connection_type == "underground" then
          -- make the underground a fake underground
          pipe_connection.connection_type = "normal"
          pipe_connection.max_underground_distance = nil
          -- set the filter to the psuedo underground pipe name
          pipe_connection.connection_category = mods["no-pipe-touching"] and "tomwub-" .. p .. "-underground" or "tomwub-underground"
          -- save collision mask for later
          underground_collision_mask = pipe_connection.underground_collision_mask
        end
      end

      -- create new visualizations for the pipe-to-ground
      local old_visualization = underground.visualization or data.raw["pipe-to-ground"]["pipe-to-ground"].visualization
      underground.visualization = {
        north = {layers = {table.deepcopy(old_visualization.south), old_visualization.north}},
        east = {layers = {table.deepcopy(old_visualization.west), old_visualization.east}},
        south = {layers = {table.deepcopy(old_visualization.north), old_visualization.south}},
        west = {layers = {table.deepcopy(old_visualization.east), old_visualization.west}}
      }
      underground.visualization.north.layers[1].shift = util.by_pixel(0, downshift)
      underground.visualization.east.layers[1].shift = util.by_pixel(0, downshift)
      underground.visualization.south.layers[1].shift = util.by_pixel(0, downshift)
      underground.visualization.west.layers[1].shift = util.by_pixel(0, downshift)

      -- update collision mask
      if not underground.collision_mask then
        underground.collision_mask = {
          layers = {
            [p .. "-underground"] = true,
            ["tomwub-underground"] = true,
            is_lower_object = true,
            water_tile = true,
            floor = true,
            transport_belt = true,
            item = true,
            car = true,
            meltable = true
          }
        }
      else
        underground.collision_mask.layers[p .. "-underground"] = true
        underground.collision_mask.layers["tomwub-underground"] = true
      end

      -- create new item, entity, and collision layer
      data.extend{
        {
          type = "item",
          name = "tomwub-" .. p,
          icon = pipe.icon or data.raw.pipe.pipe.icon,
          place_result = "tomwub-" .. p,
          flags = {"only-in-cursor"},
          stack_size = data.raw.item[p].stack_size
        },
        {
          type = "pipe",
          name = "tomwub-" .. p,
          icon = pipe.icon or data.raw.pipe.pipe.icon,
          localised_name = {"entity-name.tomwub-underground", pipe.localised_name or {"entity-name." .. pipe.name}},
          fluid_box = table.deepcopy(pipe.fluid_box),
          pictures = table.deepcopy(pipe.pictures),
          collision_box = pipe.collision_box,
          selection_box = pipe.selection_box,
          collision_mask = underground_collision_mask or { layers = {} },
          flags = {"not-upgradable", "player-creation", "placeable-neutral"},
          horizontal_window_bounding_box = pipe.horizontal_window_bounding_box,
          vertical_window_bounding_box = pipe.vertical_window_bounding_box,
          icon_draw_specification = table.deepcopy(pipe.icon_draw_specification),
          minable = pipe.minable,
          selection_priority = 255,
          placeable_by = { {item = "tomwub-" .. p, count = 1}, {item = p, count = 1} },
          is_military_target = false
        },
        {
          type = "collision-layer",
          name = p .. "-underground"
        }
      }
      if mods["no-pipe-touching"] then
        data.extend{{
          type = "collision-layer",
          name = p .. "-underground"
        }}
      end
      tomwub_pipe = data.raw.pipe["tomwub-" .. p]
      for _, pipe_connection in pairs(tomwub_pipe.fluid_box.pipe_connections) do
        pipe_connection.connection_category = mods["no-pipe-touching"] and "tomwub-" .. p .. "-underground" or "tomwub-underground"
      end
      
      -- add custom collision mask
      if mods["no-pipe-touching"] then
        tomwub_pipe.collision_mask.layers[p .. "-underground"] = true
      else
        tomwub_pipe.collision_mask.layers["tomwub-underground"] = true
      end
      -- shift everything down
      tomwub_pipe.icon_draw_specification.shift = util.by_pixel(0, downshift)
      reformat(tomwub_pipe.pictures)
      if tomwub_pipe.fluid_box.pipe_covers == nil then
        tomwub_pipe.fluid_box.pipe_covers = table.deepcopy(pipecoverspictures())
      end
      reformat(tomwub_pipe.fluid_box.pipe_covers, true)

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
        offset = util.by_pixel(0, downshift),
        distance = 0.65
      }

      -- update the selection box of the pipe
      tomwub_pipe.selection_box = {{-0.4, -0.4 + util.by_pixel(0, downshift)[2]}, {0.4, 0.4 + util.by_pixel(0, downshift)[2]}}
    
      -- if recipe exists
      if data.raw.recipe[u] then
        local ingredients = data.raw.recipe[u].ingredients
        data.raw.recipe[u].ingredients = {}
        -- add ingredient if not the associated pipe
        for _, ingredient in pairs(ingredients) do
          log(ingredient.name)
          if ingredient.name ~= p then
            data.raw.recipe[u].ingredients[#data.raw.recipe[u].ingredients+1] = ingredient
          end
        end
      end
    end
  end
end

data:extend{
  {
    type = "custom-input",
    name = "tomwub-swap-layer",
    key_sequence = "G",
    action = "lua"
  },
  {
    type = "custom-input",
    name = "tomwub-alt-mode",
    key_sequence = "ALT + V",
    action = "lua"
  },
  {
    type = "collision-layer",
    name = "tomwub-underground",
  }
}
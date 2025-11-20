local xutil = require "util"

local tags = {}

underground_total_resistances = {}

for prototype in pairs(data.raw["damage-type"]) do
  underground_total_resistances[#underground_total_resistances+1] = {
    type = prototype,
    percent = 100
  }
end

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
          underground_collision_mask = pipe_connection.underground_collision_mask or {layers = {}}
          tag = pipe_connection.connection_category
        end
      end

      -- assign new visualizations for the pipe-to-ground
      underground.visualization = xutil.ptg_visualizations

      -- set heating enrergy of pipe-to-ground to that of the pipe
      underground.heating_energy = pipe.heating_energy

      -- they can only be placed inside the map
      if data.raw.tile["out-of-map"] then
        underground_collision_mask.layers["out_of_map"] = true
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
          flags = {"not-upgradable", "player-creation", "placeable-neutral", "not-flammable"},
          resistances = underground_total_resistances,
          hide_resistances = true,
          horizontal_window_bounding_box = {{0,0},{0,0}},
          vertical_window_bounding_box = {{0,0},{0,0}},
          icon_draw_specification = table.deepcopy(pipe.icon_draw_specification or data.raw.pipe.pipe.icon_draw_specification),
          minable = pipe.minable,
          selection_priority = 255,
          placeable_by = { {item = "tomwub-" .. p, count = 1}, {item = p, count = 1} },
          is_military_target = false
        }
      }

      -- since we can only check while in the loop
      if mods["no-pipe-touching"] and table_size(data.raw["collision-layer"]) == 55 then
        if mods["color-coded-pipes"] then
          error("The mod combination specified is nonviable due to engine constraints. Please remove one of the following:\n- Actual Underground Pipes\n- No Pipe Touching\n- Color Coded Pipes")
        else
          local ptg_list = ""
          for prototype in pairs(data.raw["pipe-to-ground"]) do
            ptg_list = ptg_list .. "- " .. prototype .. "\n"
          end
          error("There are too many pipes. Please remove one of the following mods:\n" .. (
            (mods["RGBPipes"] and "- RGB Pipes\n" or "") ..
            (mods["pipe-tiers"] and "- Pipe Tiers\n" or "")
          ) .. "Or remove a mod that adds some of the following:\n" .. ptg_list)
        end
      end

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
      tomwub_pipe.fluid_box.pipe_covers = tomwub_pipe.fluid_box.pipe_covers or table.deepcopy(pipecoverspictures())
      xutil.reformat(tomwub_pipe.fluid_box.pipe_covers)

      -- hide flow pictures
      tomwub_pipe.pictures.gas_flow = nil
      tomwub_pipe.pictures.low_temperature_flow = nil
      tomwub_pipe.pictures.middle_temperature_flow = nil
      tomwub_pipe.pictures.high_temperature_flow = nil

      -- scale down the fluid icon
      tomwub_pipe.icon_draw_specification.scale = 0.35

      -- add placement visualization
      if settings.startup["pipe-opacity"].value == 0 then
        tomwub_pipe.radius_visualisation_specification = {
          sprite = {
            filename = "__the-one-mod-with-underground-bits__/graphics/placement-visualization.png",
            size = {160, 160}
          },
          offset = util.by_pixel(0, xutil.downshift),
          distance = 0.65
        }
      end

      -- update the selection box of the pipe
      tomwub_pipe.selection_box = {{-0.4, -0.4 + util.by_pixel(0, xutil.downshift)[2]}, {0.4, 0.4 + util.by_pixel(0, xutil.downshift)[2]}}
      
      -- attempt to fix recipes
      xutil.adjust_recipes(u)
    end
  end
end

require("__the-one-mod-with-underground-bits__/compatibility/prototypes/FluidMustFlow")
require("__the-one-mod-with-underground-bits__/compatibility/prototypes/elevated-pipes")
require("__the-one-mod-with-underground-bits__/compatibility/prototypes/elevated-space-pipes")
require("__the-one-mod-with-underground-bits__/compatibility/prototypes/FlowControl")
require("__the-one-mod-with-underground-bits__/compatibility/prototypes/dredgeworks")

data:extend{
  {
    type = "custom-input",
    name = "tomwub-swap-layer",
    key_sequence = "G",
    action = "lua"
  }, -- only create a generic collision mask when NPT is not installed
  not mods["no-pipe-touching"] and {
    type = "collision-layer",
    name = "tomwub-underground",
  } or nil
}

for u, underground in pairs(data.raw["pipe-to-ground"]) do
  if not underground.solved_by_tomwub then
    local directions, tag = {}

    if not mods["no-pipe-touching"] then
      tag = "tomwub-underground"
    elseif not underground.npt_compat then
      tag = "tomwub-" .. "pipe" .. "-underground"
    elseif underground.npt_compat.tag then
      tag = "tomwub-" .. underground.npt_compat.mod .. "-" .. underground.npt_compat.tag .. "-underground"
    elseif underground.npt_compat.override then
      tag = "tomwub-" .. underground.npt_compat.override .. "-underground"
    else
      error("tag not found for ptg:" .. serpent.block(underground))
    end

    for _, pipe_connection in pairs(underground.fluid_box.pipe_connections) do
      if pipe_connection.connection_type == "underground" then
        -- make the underground a fake underground
        pipe_connection.connection_type = "normal"
        pipe_connection.max_underground_distance = nil
        -- set the filter to the psuedo underground pipe name
        pipe_connection.connection_category = tag
        directions[#directions+1] = pipe_connection.direction
      end
    end

    -- turn into layers, if it exists
    underground.visualization = underground.visualization or xutil.base_visualisation
    for direction, sprite in pairs(underground.visualization or {}) do
      -- layers DNE, make into layers
      if not sprite.layers then
        underground.visualization[direction] = {layers = {[#directions + 1] = sprite}}
      else
        -- layers exist, shift over
        for j, layer in pairs(table.deepcopy(sprite.layers)) do
          underground.visualization[direction].layers[#directions + j] = layer
        end
      end
    end
    
    for i, direction in pairs(directions) do
      for j = 0, 3 do
        -- increment new direction from offset vector and add to layers
        underground.visualization[xutil.dirmap[j]].layers[i] = xutil.ptg_visualization(true)[xutil.dirmap[(direction / 4 + j) % 4]]
      end
    end

    -- update collision mask
    underground.collision_mask = underground.collision_mask or {}
    underground.collision_mask.layers = underground.collision_mask.layers or {
      is_lower_object = true,
      water_tile = true,
      floor = true,
      transport_belt = true,
      item = true,
      car = true,
      meltable = true
    }
    underground.collision_mask.layers[tag] = true

    -- attempt to fix recipes
    xutil.adjust_recipes(u)
  end

  underground.solved_by_tomwub = nil
  underground.solved_by_npt = nil
  underground.npt_compat = nil
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
  "infinity-pipe",
  "valve"
 } do
  for _, prototype in pairs(data.raw[type] or {}) do
    if not prototype.ignore_by_tomwub then
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
    else
      prototype.ignore_by_tomwub = nil
    end
  end
end

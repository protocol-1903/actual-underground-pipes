local tags = {}

_G.underground_total_resistances = {}

for prototype in pairs(data.raw["damage-type"]) do
  underground_total_resistances[#underground_total_resistances+1] = {
    type = prototype,
    percent = 100
  }
end

for u, underground in pairs(data.raw["pipe-to-ground"]) do
  if not underground.ignore_by_tomwub then
    local i, j = u:find("-to-ground", nil, true)
    if not i then
       i, j = u:find("-underground", nil, true)
    end
    local p = i and j and u:sub(1, i - 1) .. (j and u:sub(j + 1) or "")
    local pipe = data.raw.pipe[p]
    if pipe then
      local mask, layer, connection_category = tomwub.adjust_ptg(underground, p)
      underground.heating_energy = pipe.heating_energy
      local u_pipe = tomwub.make_tomwub_variant(pipe, mask, layer, connection_category)
      tomwub.reformat(u_pipe.pictures)
      u_pipe.fluid_box.pipe_covers = u_pipe.fluid_box.pipe_covers or table.deepcopy(pipecoverspictures())
      tomwub.reformat(u_pipe.fluid_box.pipe_covers)
      tomwub.adjust_recipes(u)

      -- save the tag for later use with assembling machines
      tags[#tags+1] = connection_category
    else
      error("Associated pipe [" .. p .. "] not found for [" .. u .. "]")
    end
  end
end

-- they can only be placed inside the map
if data.raw.tile["out-of-map"] and settings.startup["npt-tomwub-weaving"].value then
  for _, layer in pairs(tags) do
    data.raw.tile["out-of-map"].collision_mask.layers[layer] = true
  end
end

require("__the-one-mod-with-underground-bits__/compatibility/prototypes/FluidMustFlow")
require("__the-one-mod-with-underground-bits__/compatibility/prototypes/FlowControl")
require("__the-one-mod-with-underground-bits__/compatibility/prototypes/dredgeworks")
require("__the-one-mod-with-underground-bits__/compatibility/prototypes/underground-heat-pipe")

for u, underground in pairs(data.raw["pipe-to-ground"]) do
  if not underground.solved_by_tomwub and not underground.ignore_by_tomwub then
    local directions, connection_category = {}

    if not mods["no-pipe-touching"] then
      connection_category = "tomwub-underground"
    elseif not underground.npt_compat then
      connection_category = "tomwub-" .. "pipe" .. "-underground"
    elseif underground.npt_compat.tag then
      connection_category = "tomwub-" .. underground.npt_compat.mod .. "-" .. underground.npt_compat.tag .. "-underground"
    elseif underground.npt_compat.override then
      connection_category = "tomwub-" .. underground.npt_compat.override .. "-underground"
    else
      error("tag not found for ptg:" .. serpent.block(underground))
    end

    for _, pipe_connection in pairs(underground.fluid_box.pipe_connections) do
      if pipe_connection.connection_type == "underground" then
        -- make the underground a fake underground
        pipe_connection.connection_type = "normal"
        pipe_connection.max_underground_distance = nil
        -- set the filter to the psuedo underground pipe name
        pipe_connection.connection_category = connection_category
        directions[#directions+1] = pipe_connection.direction
      end
    end

    -- turn into layers, if it exists
    underground.visualization = underground.visualization or tomwub.base_visualisation
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
        underground.visualization[tomwub.dirmap[j]].layers[i] = tomwub.ptg_visualization(true)[tomwub.dirmap[(direction / 4 + j) % 4]]
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
    underground.collision_mask.layers[settings.startup["npt-tomwub-weaving"].value and connection_category or "tomwub-underground"] = true

    -- attempt to fix recipes
    tomwub.adjust_recipes(u)
  elseif underground.ignore_by_tomwub then
    log("ignoring prototype: " .. u)
    underground.ignore_by_tomwub = nil
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
    if not prototype.ignore_by_tomwub and not prototype.solved_by_tomwub then
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
    elseif prototype.ignore_by_tomwub then
      log("ignoring prototype: " .. prototype.name)
      prototype.ignore_by_tomwub = nil
    end
    prototype.solved_by_tomwub = nil
  end
end
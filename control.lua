script.on_init(function (event)
  storage.tomwub = {}
end)

local event_filter = {{filter = "type", type = "pipe"}, {filter = "type", type = "storage-tank"}}

local function is_same_type(self, check)
  return #self > 7 and self:sub(8) == check or self == check
end

script.on_event(defines.events.on_player_controller_changed, function (event)
  local player = game.players[event.player_index]

  if not storage.tomwub[player.index] then return end

  local item = player.cursor_ghost and player.cursor_ghost.name.name or
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name or nil
  local quality = player.cursor_ghost and player.cursor_ghost.quality or 
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.quality or nil
  local count = storage.tomwub[player.index].count

  if not item or item:sub(1,7) ~= "tomwub-" then return end

  if player.controller_type == defines.controllers.remote and event.old_type ~= defines.controllers.editor and count > 0 then
    -- was previously holding item, just put it away so put pipes back into inventory
    player.character.get_main_inventory().insert {
      name = item:sub(8, -1),
      count = count,
      quality = quality
    }
  end
  storage.tomwub[player.index].count = -3 - count
end)

-- when pipetting an underground pipe, put that one in the hand instead
script.on_event(defines.events.on_player_pipette, function (event)
  local player = game.players[event.player_index]

  -- only run if selected entity (duh)
  if not player.selected then return end

  local name = player.selected and (player.selected.name == "entity-ghost" and player.selected.ghost_name or player.selected.name)
  local quality = player.selected and player.selected.quality

  -- end if not one of ours
  if name:sub(1,7) ~= "tomwub-" then return end

  -- if item for this entity exists (should be of the same name)
  if prototypes.item[name] then
    if not player.cursor_ghost then
      -- should fill normally with stack change script
      storage.tomwub[player.index] = {
        item = name,
        count = -1,
        quality = quality
      }
    end
    player.clear_cursor()
    player.cursor_ghost = {
      name = name,
      quality = quality
    }
  else -- might be a subentity (duct variant, flow config variant, etc) that has no direct item_to_place
    if not player.cursor_ghost then
      -- should fill normally with stack change script
      storage.tomwub[player.index] = {
        item = "tomwub-" .. prototypes.entity[name].mineable_properties.products[1].name,
        count = -1,
        quality = quality
      }
    end
    player.clear_cursor()
    player.cursor_ghost = {
      name = "tomwub-" .. prototypes.entity[name].mineable_properties.products[1].name,
      quality = quality
    }
  end
end)

-- if ghost underground selected, check if it needs refilling
script.on_event(defines.events.on_player_cursor_stack_changed, function (event)

  local player = game.players[event.player_index]
  if not player then return end

  -- if in remote view do nothing
  if player.controller_type == defines.controllers.remote then return end

  local item = player.cursor_ghost and player.cursor_ghost.name.name or
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name or nil
  local quality = player.cursor_ghost and player.cursor_ghost.quality or 
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.quality or nil

  -- if the player somehow broke this... give up
  if storage.tomwub[event.player_index] == nil then goto continue end

  old_item = storage.tomwub[event.player_index].item
  old_count = storage.tomwub[event.player_index].count
  old_quality = storage.tomwub[event.player_index].quality

  -- if just swapped using custom key, go to end
  if old_count == -2 then goto continue end

  -- was previously holding item but placed last one, signaled by on_built_entity OR just pipetted a tomwub pipe (creating ghost item)
  if player.cursor_ghost and old_count == -1 then

    -- get count and remove from inventory
    local removed = player.get_main_inventory().remove{
      name = old_item:sub(8,-1),
      count = player.cursor_ghost.name.stack_size,
      quality = old_quality
    }

    -- if none removed
    if removed == 0 then goto continue end

    -- find open slot for hand to go
    local _, stack = player.get_main_inventory().find_empty_stack()

    -- put into cursor
    player.cursor_stack.set_stack {
      name = player.cursor_ghost.name.name,
      count = removed,
      quality = quality
    }

    -- set hand location to preserve place for player to put items
    player.hand_location = {
      inventory = player.get_main_inventory().index,
      slot = stack
    }
  elseif player.is_cursor_empty() and old_count > 0 and old_item:sub(1,7) == "tomwub-" then
    -- was previously holding item, just put it away so put pipes back into inventory

    -- get amount added to inventory
    local amount_inserted = player.get_main_inventory().insert {
      name = old_item:sub(8, -1),
      count = old_count,
      quality = old_quality
    }
  elseif not player.is_cursor_empty() and old_count < -3 and item:sub(1,7) == "tomwub-" then

    local amount_removed = player.controller_type == defines.controllers.editor and -3 - old_count or player.get_main_inventory().remove{
      name = item:sub(8, -1),
      count = -3 - old_count,
      quality = quality
    }

    if removed == 0 then goto continue end

    -- find open slot for hand to go
    local _, stack = player.get_main_inventory().find_empty_stack()

    if not stack then
      amount_removed = player.get_main_inventory().remove{
        name = item:sub(8, -1),
        count = player.cursor_ghost.stack_size - amount_removed,
        quality = quality
      }

      _, stack = player.get_main_inventory().find_empty_stack()

      if not stack then error("stack not created") end
    end

    -- was previously holding item, just put it away so put pipes back into inventory
    player.cursor_stack.set_stack {
      name = item,
      count = amount_removed,
      quality = old_quality
    }

    -- set hand location to preserve place for player to put items
    player.hand_location = {
      inventory = player.get_main_inventory().index,
      slot = stack
    }
  end

  ::continue:: -- something skipped to end

  -- set the previous item and count
  storage.tomwub[event.player_index] = {
    item = item,
    count = player.cursor_stack and player.cursor_stack.count or 0,
    quality = quality
  }
end)

-- on placed entity
function handle(event)

  -- teleport valid entities so that pipe visualizations appear properly
  if event.entity.name:sub(1,7) == "tomwub-" then
    event.entity.teleport(event.entity.position)
  else
    local entities = event.entity.surface.find_entities_filtered{
      area = {
        {
          event.entity.position.x - event.entity.prototype.collision_box.left_top.x,
          event.entity.position.y - event.entity.prototype.collision_box.left_top.y
        },
        {
          event.entity.position.x + event.entity.prototype.collision_box.right_bottom.x,
          event.entity.position.y + event.entity.prototype.collision_box.right_bottom.y
        }
      }
    }
    for _, pipe in pairs(entities) do
      if pipe.name:sub(1,7) == "tomwub-" then
        pipe.teleport(pipe.position)
      end
    end
  end

  player = event.player_index and game.players[event.player_index]
  if not player or not storage.tomwub[player.index] then return end

  -- if player just placed last item, then signal to script to update hand again
  if player.is_cursor_empty() and storage.tomwub[player.index].item and storage.tomwub[player.index].item:sub(1,7) == "tomwub-" and storage.tomwub[player.index].count == 1 then
    storage.tomwub[player.index].count = -1

    -- set ghost cursor
    player.cursor_ghost = {
      name = event.entity.name,
      quality = event.entity.quality
    }
  end
end

script.on_event(defines.events.on_built_entity, handle, event_filter)
script.on_event(defines.events.on_robot_built_entity, handle, event_filter)
script.on_event(defines.events.script_raised_built, handle, event_filter)
script.on_event(defines.events.script_raised_revive, handle, event_filter)

-- swap between aboveground and belowground layers
script.on_event("tomwub-swap-layer", function(event)

  player = game.players[event.player_index]
  if not player then return end

  local item = player.cursor_ghost and player.cursor_ghost.name.name or
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name or nil
  local quality = player.cursor_ghost and player.cursor_ghost.quality or 
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.quality or nil
  local count = player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.count or 0

  -- if invalid or not pipe, return
  if player.is_cursor_empty() or player.cursor_record or not (item:sub(-4, -1) == "pipe" or is_same_type(item, "duct") or is_same_type(item, "duct-small") or is_same_type(item, "duct-long") or is_same_type(item, "duct-curve") or is_same_type(item, "duct-t-junction") or is_same_type(item, "duct-cross")) or item:sub(1, 4) == "hot-" then return end
  -- yes it works no i dont know why
  -- also man .valid_for_read is so powerful
  -- it's hopefully a valid item, so do a little switcheroo

  local stack_size = player.cursor_ghost and player.cursor_ghost.name.stack_size or
    player.cursor_stack.prototype.stack_size

  -- if the player somehow broke this... give up
  if storage.tomwub[event.player_index] == nil then goto continue end

  -- holding underground, switch to pipe
  if item:sub(1,7) == "tomwub-" then
    -- clear cursor
    player.clear_cursor()
    -- currently ghost entity, swap with ghost
    if count == 0 then
      player.cursor_ghost = {
        name = item:sub(8, -1),
        quality = quality
      }
    else -- non-ghost, insert from inventory
      -- find open slot for hand to go
      local _, stack = player.get_main_inventory().find_empty_stack()
      -- put into cursor
      player.cursor_stack.set_stack {
        name = item:sub(8, -1),
        count = count,
        quality = quality
      }
      -- set hand location to preserve place for player to put items
      player.hand_location = {
        inventory = player.get_main_inventory().index,
        slot = stack
      }
    end
  elseif prototypes.item["tomwub-" .. item] then -- verify tomwub variant exists
    -- clear cursor
    player.clear_cursor()
    -- currently ghost entity, swap with ghost
    if count == 0 then
      player.cursor_ghost = {
        name = "tomwub-" .. item,
        quality = quality
      }
    else -- non-ghost, insert from inventory
      -- get amount added to inventory
      local removed = player.get_main_inventory().remove {
        name = item,
        count = count,
        quality = quality
      }
      -- find open slot for hand to go
      local _, stack = player.get_main_inventory().find_empty_stack()
      -- put into cursor
      player.cursor_stack.set_stack {
        name = "tomwub-" .. item,
        count = removed,
        quality = quality
      }
      -- set hand location to preserve place for player to put items
      player.hand_location = {
        inventory = player.get_main_inventory().index,
        slot = stack
      }
    end
  end

  ::continue:: -- something skipped to end

  -- set the previous item and count
  storage.tomwub[event.player_index] = {
    item = item,
    count = -2,
    quality = quality
  }
end)

-- okay so to do the bit with mining, check if the tomwub pipe mined is of the same type as the one in the hand (if at all)
-- if its the same, do nothing
-- if different, search entity position for whatever might have been removed instead of the type in hand
-- if nothing found, cancel
-- if something found, remove that one instead (add to buffer inventory) and replace the entity that just got mined (so nothing is actually mined and all fluidboxes are preserved)


-- teleport pipes so the visualization is on the bottom

-- The only thing we're doing is auto-join, so don't even bother if it's not enabled
if not script.active_mods["FluidMustFlow"] or not settings.startup["fmf-enable-duct-auto-join"].value then
  return
end

-- The entire file below this point is copied in src/prototypes/tips-and-tricks.lua for the drag building simulation

--- Calculates the midpoint between two positions.
--- @param pos_1 MapPosition
--- @param pos_2 MapPosition
--- @return MapPosition
local function get_midpoint(pos_1, pos_2)
  return {
    x = (pos_1.x + pos_2.x) / 2,
    y = (pos_1.y + pos_2.y) / 2,
  }
end

--- @param e EventData.on_built_entity|EventData.on_robot_built_entity|EventData.script_raised_built|EventData.script_raised_revive
local function join_ducts(e)
  --- @type LuaEntity
  local entity = e.entity
  if not entity or not entity.valid then
    return
  end

  for _, connection in pairs(entity.fluidbox.get_pipe_connections(1)) do
    local neighbour = entity.surface.find_entity(entity.name, connection.target_position)
    if neighbour then
      local direction = entity.direction
      local force = entity.force
      local last_user = entity.last_user
      local name = entity.name == "tomwub-duct-small" and "tomwub-duct" or "tomwub-duct-long"
      local position = get_midpoint(entity.position, neighbour.position)
      local surface = entity.surface

      entity.destroy({ raise_destroy = true })
      neighbour.destroy({ raise_destroy = true })

      surface.create_entity({
        name = name,
        position = position,
        direction = direction,
        force = force,
        player = last_user,
        raise_built = true,
        create_build_effect_smoke = false,
      })

      -- Only do one join per build
      break
    end
  end
end

function handle(event)
  if event.entity.type == "storage-tank" or event.entity.type == "pipe" or event.entity.type == "pump" then
    -- teleport valid entities so that pipe visualizations appear properly
    if event.entity.name:sub(1,7) == "tomwub-" then
      event.entity.teleport(event.entity.position)
    else
      local entities = event.entity.surface.find_entities_filtered{
        area = {
          {
            event.entity.position.x - event.entity.prototype.collision_box.left_top.x,
            event.entity.position.y - event.entity.prototype.collision_box.left_top.y
          },
          {
            event.entity.position.x + event.entity.prototype.collision_box.right_bottom.x,
            event.entity.position.y + event.entity.prototype.collision_box.right_bottom.y
          }
        }
      }
      for _, pipe in pairs(entities) do
        if pipe.name:sub(1,7) == "tomwub-" then
          pipe.teleport(pipe.position)
        end
      end
    end
  
    player = event.player_index and game.players[event.player_index]
    if not player then return end
  
    -- if player just placed last item, then signal to script to update hand again
    if player.is_cursor_empty() and storage.tomwub[player.index].item and storage.tomwub[player.index].item:sub(1,7) == "tomwub-" and storage.tomwub[player.index].count == 1 then
      storage.tomwub[player.index].count = -1
  
      -- set ghost cursor
      player.cursor_ghost = {
        name = event.entity.name,
        quality = event.entity.quality
      }
    end
  end
  if event.entity.name == "tomwub-duct-small" or event.entity.name == "tomwub-duct" then
    join_ducts(event)
  end
end
script.on_event(defines.events.on_built_entity, handle, event_filter)
script.on_event(defines.events.on_robot_built_entity, handle, event_filter)
script.on_event(defines.events.script_raised_built, handle, event_filter)
script.on_event(defines.events.script_raised_revive, handle, event_filter)

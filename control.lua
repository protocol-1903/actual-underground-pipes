script.on_init(function ()
  storage.tomwub = {}
  storage.weaving = settings.startup["npt-tomwub-weaving"].value
end)

script.on_configuration_changed(function (event)
  storage.tomwub = storage.tomwub or {}
  if script.active_mods["no-pipe-touching"] and (not (event.mod_changes["no-pipe-touching"] or {}).old_version and storage.weaving ~= settings.startup["npt-tomwub-weaving"].value and not settings.startup["npt-tomwub-weaving"].value or
    storage.weaving ~= settings.startup["npt-tomwub-weaving"].value and not settings.startup["npt-tomwub-weaving"].value and event.mod_startup_settings_changed) then
    game.print("Underground pipe layers can no longer be stacked by default. If you wish to enable this feature, please enable the mod setting: Enable underground pipe weaving")
  end
  storage.weaving = settings.startup["npt-tomwub-weaving"].value
end)

local event_filter = {{filter = "type", type = "pipe"}, {filter = "type", type = "storage-tank"}}

script.on_event(defines.events.on_player_controller_changed, function (event)
  local player = game.get_player(event.player_index)

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

---@param event EventData.on_selected_entity_changed
local function on_selected(event)
  local player = game.get_player(event.player_index)
  local entity = player.selected
  if not entity then return end
  local prototype = entity.name == "entity-ghost" and entity.ghost_prototype or entity.prototype
  local item = player.cursor_ghost and player.cursor_ghost.name.name or
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name or nil
  if (not item or item:sub(1,7) ~= "tomwub-") and prototype.name:sub(1,7) == "tomwub-" then
    player.selected = nil
  elseif item and item:sub(1,7) == "tomwub-" and prototype.name:sub(1,7) ~= "tomwub-" then
    player.selected = nil
  end
end

-- only allow selecting an underground pipe if you have one in hand
script.on_event(defines.events.on_selected_entity_changed, on_selected)

-- if ghost underground selected, check if it needs refilling
---@param event EventData.on_player_cursor_stack_changed
script.on_event(defines.events.on_player_cursor_stack_changed, function (event)
  local player = game.get_player(event.player_index)

  -- if in remote view do nothing
  if player.controller_type == defines.controllers.remote then return end

  local item = player.cursor_ghost and player.cursor_ghost.name.name or
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name or nil
  local count = not player.cursor_ghost and player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.count or nil
  local quality = player.cursor_ghost and player.cursor_ghost.quality or
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.quality or nil

  storage.tomwub[event.player_index] = storage.tomwub[event.player_index] or {}

  local old_item = storage.tomwub[event.player_index].item or ""
  local old_count = storage.tomwub[event.player_index].count or 0
  local old_quality = storage.tomwub[event.player_index].quality or ""

  -- if just swapped using custom key (old_count == -2), will skip to end
  -- was previously holding item but placed last one, signaled by on_built_entity
  if old_count == -1 and player.cursor_ghost then

    -- get count and remove from inventory
    local removed = player.get_main_inventory().remove{
      name = old_item:sub(8,-1),
      count = player.cursor_ghost.name.stack_size,
      quality = old_quality
    }

    -- only continue if some were found
    if removed ~= 0 then
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
    end
  elseif old_count > 0 and item ~= old_item and old_item:sub(1,7) == "tomwub-" then
    -- was previously holding item, just put it away so put pipes back into inventory

    -- get amount added to inventory
    local inserted = player.get_main_inventory().insert {
      name = old_item:sub(8, -1),
      count = old_count,
      quality = old_quality
    }

    on_selected(event)

    -- something must be obstructing the cursor, put it back
    if inserted ~= old_count then
      -- the only reason to do it conditionally is if the player cannot insert them, then it'll play some noise and notify the player for no reason
      if count and player.can_insert{
        name = item,
        count = count,
        quality = quality
      } then
        player.clear_cursor()
      end

      -- notify the player
      player.play_sound{path = "utility/cannot_build"}
      player.create_local_flying_text{text = {"cant-clear-cursor", prototypes.item[old_item].localised_name}, create_at_cursor = true}

      player.cursor_stack.set_stack{
        name = old_item,
        count = old_count - inserted,
        quality = old_quality
      }

      -- set the previous item and count
      storage.tomwub[event.player_index] = {
        item = old_item,
        count = -2,
        quality = old_quality
      }

      return -- return early, we don't want to run other code
    end
  elseif old_count < -3 and not player.is_cursor_empty() and item:sub(1,7) == "tomwub-" then

    local amount_removed = player.controller_type == defines.controllers.editor and -3 - old_count or player.get_main_inventory().remove{
      name = item:sub(8, -1),
      count = -3 - old_count,
      quality = quality
    }

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

  -- set the previous item and count
  storage.tomwub[event.player_index] = {
    item = item,
    count = player.cursor_stack and player.cursor_stack.count or 0,
    quality = quality
  }
end)

-- on placed entity
local function handle(event)

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

  if not event.player_index or not storage.tomwub[event.player_index] then return end
  local player = game.get_player(event.player_index)

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

  local player = game.get_player(event.player_index)

  local item = player.cursor_ghost and player.cursor_ghost.name.name or
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name or ""
  local quality = player.cursor_ghost and player.cursor_ghost.quality or 
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.quality or nil
  local count = player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.count or 0

  -- if invalid or not pipe, return
  if player.is_cursor_empty() or item:sub(1,7) ~= "tomwub-" and not prototypes.item["tomwub-" .. item] then return end
  -- yes it works no i dont know why
  -- also man .valid_for_read is so powerful
  -- it's hopefully a valid item, so do a little switcheroo

  -- holding underground, switch to pipe
  if item:sub(1,7) == "tomwub-" then
    player.clear_cursor()
    -- currently ghost entity, swap with ghost
    if count == 0 then
      player.cursor_ghost = {
        name = item:sub(8, -1),
        quality = quality
      }
    else -- non-ghost, insert from inventory
      -- put into cursor
      player.cursor_stack.set_stack {
        name = item:sub(8, -1),
        count = count,
        quality = quality
      }
      -- find open slot for hand to go
      local _, stack = player.get_main_inventory().find_empty_stack()
      -- set hand location to preserve place for player to put items
      if stack then
        player.hand_location = {
          inventory = player.get_main_inventory().index,
          slot = stack
        }
      end
    end
  elseif prototypes.item["tomwub-" .. item] then -- verify tomwub variant exists
    -- currently ghost entity, swap with ghost
    if count == 0 then
      player.cursor_ghost = {
        name = "tomwub-" .. item,
        quality = quality
      }
    else -- non-ghost, convert
      player.cursor_stack.set_stack {
        name = "tomwub-" .. item,
        count = count,
        quality = quality
      }
      -- find open slot for hand to go
      local _, stack = player.get_main_inventory().find_empty_stack()
      -- set hand location to preserve place for player to put items (if possible)
      if stack then
        player.hand_location = {
          inventory = player.get_main_inventory().index,
          slot = stack
        }
      end
    end
  end

  -- update selected entity
  on_selected(event)

  -- set the previous item and count
  storage.tomwub[event.player_index] = {
    item = item,
    count = -2,
    quality = quality
  }
end)

require("compatibility.scripts.FluidMustFlow")
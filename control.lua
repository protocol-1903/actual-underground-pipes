script.on_init(function (event)
  storage.tomwub = {}
end)

local function is_same_type(self, check)
  game.print((#self > 7 and self:sub(8) or "nil") .. ":" .. check)
  game.print(self .. ":" .. check)
  return #self > 7 and self:sub(8) == check or self == check
end

-- if ghost underground selected, check if it needs refilling
script.on_event(defines.events.on_player_cursor_stack_changed, function (event)

  player = game.get_player(event.player_index)
  if not player then return end

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
  if player.is_cursor_empty() and storage.tomwub[event.player_index].count == -1 or player.cursor_ghost and item and item:sub(1,7) == "tomwub-" then

    game.print(item)

    -- get count and remove from inventory
    local removed = player.get_main_inventory().remove {
      name = item:sub(8,-1),
      count = player.cursor_ghost.name.stack_size,
      quality = quality
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
script.on_event(defines.events.on_built_entity, function (event)

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

  player = game.get_player(event.player_index)
  if not player then return end

  -- if player just placed last item, then signal to script to update hand again
  if player.is_cursor_empty() and storage.tomwub[event.player_index].count == 1 then
    storage.tomwub[event.player_index].count = -1

    -- set ghost cursor
    player.cursor_ghost = {
      name = event.entity.name,
      quality = event.entity.quality
    }
  end
end, {{filter = "type", type = "pipe"}, {filter = "type", type = "storage-tank"}})

-- swap between aboveground and belowground layers
script.on_event("tomwub-swap-layer", function(event)

  player = game.get_player(event.player_index)
  if not player then return end

  local item = player.cursor_ghost and player.cursor_ghost.name.name or
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name or nil
  local quality = player.cursor_ghost and player.cursor_ghost.quality or 
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.quality or nil
  local count = player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.count or 0

  -- if invalid or not pipe, return
  if player.is_cursor_empty() or not (item:sub(-4, -1) == "pipe" or is_same_type(item, "duct") or is_same_type(item, "duct-small") or is_same_type(item, "duct-long") or is_same_type(item, "duct-curve") or is_same_type(item, "duct-t-junction") or is_same_type(item, "duct-cross")) or item:sub(1, 4) == "hot-" then return end
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
  else -- holding pipe, switch to underground
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
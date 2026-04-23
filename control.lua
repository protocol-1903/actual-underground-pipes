require "__perel__.util.scripts.fluids"
require "__core__.lualib.util"
local event_filter = {{filter = "type", type = "pipe"}, {filter = "type", type = "storage-tank"}, {filter = "ghost_type", type = "pipe"}, {filter = "ghost_type", type = "storage-tank"}}

script.on_init(function ()
  storage.tomwub = {}
  storage.weaving = settings.startup["npt-tomwub-weaving"].value
  storage.trackers = {}
  storage.tracker_count = 0
  storage.scans = {}
  storage.last_index = nil
end)

script.on_configuration_changed(function (event)
  storage.tomwub = storage.tomwub or {}
  storage.trackers = storage.trackers or {}
  storage.tracker_count = storage.tracker_count or 0
  storage.last_index = storage.last_index or nil
  storage.scans = storage.scans or {}
  if script.active_mods["no-pipe-touching"] and (not (event.mod_changes["no-pipe-touching"] or {}).old_version and storage.weaving ~= settings.startup["npt-tomwub-weaving"].value and not settings.startup["npt-tomwub-weaving"].value or
    storage.weaving ~= settings.startup["npt-tomwub-weaving"].value and not settings.startup["npt-tomwub-weaving"].value and event.mod_startup_settings_changed) then
    game.print("Underground pipe layers can no longer be stacked by default. If you wish to enable this feature, please enable the mod setting: Enable underground pipe weaving")
  end
  storage.weaving = settings.startup["npt-tomwub-weaving"].value
end)

local ticks_per_scan = 181 -- ticks between full scans for new entities
local subscans = 6 -- size of subscan grid. 3 means 9 total scans, in a 3x3 square
local ticks_per_update = 251 -- ticks between tracker checks
local checks_per_update = 4 -- checks before a tracker's tint and mask are updated

local function get_tint(entity)
  return entity.type == "entity-ghost" and prototypes.utility_constants.ghost_shaderless_tint.ghost_tint or
    util.multiply_color(entity.get_fluid(1) and prototypes.fluid[entity.get_fluid(1).name].base_color or {1, 1, 1, 1}, settings.global["pipe-opacity"].value)
end

local indicator_alts = {}
if script.active_mods.FluidMustFlow and not script.active_mods["duct-duct-go"] then
  indicator_alts["tomwub-duct-small"] = {
    [defines.direction.north] = "tomwub-duct-small-indicator-05",
    [defines.direction.east] = "tomwub-duct-small-indicator-10",
    [defines.direction.south] = "tomwub-duct-small-indicator-05",
    [defines.direction.west] = "tomwub-duct-small-indicator-10"
  }
  indicator_alts["tomwub-duct"] = {
    [defines.direction.north] = "tomwub-duct-indicator-05",
    [defines.direction.east] = "tomwub-duct-indicator-10",
    [defines.direction.south] = "tomwub-duct-indicator-05",
    [defines.direction.west] = "tomwub-duct-indicator-10"
  }
  indicator_alts["tomwub-duct-long"] = {
    [defines.direction.north] = "tomwub-duct-long-indicator-05",
    [defines.direction.east] = "tomwub-duct-long-indicator-10",
    [defines.direction.south] = "tomwub-duct-long-indicator-05",
    [defines.direction.west] = "tomwub-duct-long-indicator-10"
  }
  indicator_alts["tomwub-duct-cross"] = {
    [defines.direction.north] = "tomwub-duct-north-indicator-15",
    [defines.direction.east] = "tomwub-duct-east-indicator-15",
    [defines.direction.south] = "tomwub-duct-south-indicator-15",
    [defines.direction.west] = "tomwub-duct-west-indicator-15",
  }
  indicator_alts["tomwub-duct-curve"] = {
    [defines.direction.north] = "tomwub-duct-curve-indicator-09",
    [defines.direction.east] = "tomwub-duct-curve-indicator-03",
    [defines.direction.south] = "tomwub-duct-curve-indicator-06",
    [defines.direction.west] = "tomwub-duct-curve-indicator-12",
  }
  indicator_alts["tomwub-duct-t-junction"] = {
    [defines.direction.north] = "tomwub-duct-t-junction-indicator-11",
    [defines.direction.east] = "tomwub-duct-t-junction-indicator-07",
    [defines.direction.south] = "tomwub-duct-t-junction-indicator-14",
    [defines.direction.west] = "tomwub-duct-t-junction-indicator-13",
  }
end

local function get_indicator(entity)
  local name = entity.name == "entity-ghost" and entity.ghost_name or entity.name
  return indicator_alts[name] and indicator_alts[name][entity.direction] or name:find("tomwub-duct", nil, true) and "tomwub-duct-indicator-%02d" or "tomwub-indicator-%02d"
end

local function update_render(tracker, update)
  if not tracker then return end
  local entity = tracker.entity
  if not entity or not entity.valid then return end
  local players = {}
  for index in pairs(tracker.players) do
    players[#players+1] = index
  end
  tracker.render.players = players
  if update or not tracker.render or not tracker.render.valid then
    local mask = perel.get_pipe_connection_bitmask(entity)
    if mask ~= tracker.mask then
      tracker.mask = mask -- update connection mask of tracker
      tracker.render.sprite = get_indicator(entity):format(mask)
    end
    -- update tint
    if tracker.entity.type ~= "entity-ghost" then
      tracker.tint = get_tint(entity) -- update tint of tracker
    end
  end
end

local function update_tracker(entity)
  if storage.trackers[entity.unit_number] then
    storage.trackers[entity.unit_number].last_tick = game.tick
    return
  end
  storage.tracker_count = storage.tracker_count + 1
  local mask = perel.get_pipe_connection_bitmask(entity)
  local tracker = {
    entity = entity,
    last_tick = game.tick,
    updates = 0,
    players = {},
    mask = mask,
    render = rendering.draw_sprite{
      sprite = get_indicator(entity):format(mask),
      target = entity.position,
      surface = entity.surface_index,
      tint = get_tint(entity),
      render_layer = "elevated-higher-object"
    }
  }
  storage.trackers[entity.unit_number] = tracker
end

local function register_for_tracker(tracker, player_index)
  if player_index and not tracker.players[player_index] then
    update_render(tracker)
    tracker.render.visible = true
    local players = tracker.render.players or {}
    players[#players+1] = player_index
    tracker.render.players = players
    tracker.players[player_index] = true
  end
end

local function deregister_trackers(player_index)
  for _, tracker in pairs(storage.trackers) do
    if tracker.render.valid and tracker.players[player_index] then
      local players = tracker.render.players or {}
      for i, player in pairs(players) do
        if player.index == player_index then
          table.remove(players, i)
          break
        end
      end
      tracker.render.players = players
      if #players == 0 then
        tracker.render.visible = false
      end
    end
    tracker.players[player_index] = nil
  end
end

local underground_pipes_by_mask = {}
local targets = {}

local function register_trackers(player_index, full_scan)
  local player = game.get_player(player_index)

  local item = player.cursor_ghost and player.cursor_ghost.name or
  player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.prototype or nil
  if not item then return end

  local place_result = item.place_result
  if not place_result or place_result.name:sub(1, 7) ~= "tomwub-" then return end

  local scan_index = storage.scans[player_index] or 0
  scan_index = (scan_index + 1) % subscans ^ 2
  storage.scans[player_index] = scan_index

  local x, y = scan_index % subscans, math.floor(scan_index / subscans)
  local half = subscans / 2
  local ref = player.position
  local dist = player.mod_settings["tomwub-underground-indicators-range"].value / (full_scan and 1 or subscans)
  local offset = full_scan and {x = 0, y = 0} or {
    x = x < math.floor(half) and - dist * (half - x - 0.5) or x + 1 > math.ceil(half) and dist * (x - half + 0.5) or 0,
    y = y < math.floor(half) and - dist * (half - y - 0.5) or y + 1 > math.ceil(half) and dist * (y - half + 0.5) or 0
  }

  for layer in pairs(place_result.collision_mask.layers) do
    if not targets[layer] then
      targets[layer] = {}
      for target in pairs(prototypes.get_entity_filtered{{filter = "collision-mask", mask = layer, mask_mode = "collides"}}) do
        targets[layer][#targets[layer]+1] = target
      end
    end
  end
  for _, type in pairs{
    "name",
    "ghost_name"
  } do
    for _, entity in pairs(player.surface.find_entities_filtered{
      area = {
        {
          ref.x + offset.x - dist / 2,
          ref.y + offset.y - dist / 2
        },
        {
          ref.x + offset.x + dist / 2,
          ref.y + offset.y + dist / 2
        }
      },
      [type] = targets[place_result.name]
    }) do
      if (entity.name == "entity-ghost" and entity.ghost_name or entity.name):sub(1, 7) == "tomwub-" then
        update_tracker(entity)
        register_for_tracker(storage.trackers[entity.unit_number], player_index)
      end
    end
  end
end

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
  if event.old_type == defines.controllers.remote then
    storage.tomwub[player.index].count = nil
    return
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
    local entities = player.surface.find_entities_filtered{position = entity.position, collision_mask = prototype.collision_mask.layers, invert = true}
    for _, entity in pairs(entities) do
      local name = entity.name == "ghost-entity" and entity.ghost_name or entity.name
      if name:sub(1,7) ~= "tomwub-" then
        player.selected = entity
        return
      end
    end
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
    deregister_trackers(player.index)

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
local function on_built(event)
  -- teleport valid entities so that pipe visualizations appear properly
  if event.entity.name:sub(1,7) == "tomwub-" then
    event.entity.teleport(event.entity.position)

    update_tracker(event.entity)
    register_for_tracker(storage.trackers[event.entity.unit_number], event.player_index)
    for _, e in pairs(perel.get_fluidbox_neighoburs(event.entity)) do
      update_render(storage.trackers[e.unit_number], true)
    end
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

script.on_event(defines.events.on_built_entity, on_built, event_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, event_filter)
script.on_event(defines.events.on_space_platform_built_entity, on_built, event_filter)
script.on_event(defines.events.script_raised_built, on_built, event_filter)
script.on_event(defines.events.script_raised_revive, on_built, event_filter)

local function on_destroyed(event)
  local tracker = storage.trackers[event.entity.unit_number]
  if not tracker then return end
  tracker.render.destroy()
end

script.on_event(defines.events.on_player_mined_entity, on_destroyed, event_filter)
script.on_event(defines.events.on_robot_mined_entity, on_destroyed, event_filter)
script.on_event(defines.events.on_space_platform_mined_entity, on_destroyed, event_filter)
script.on_event(defines.events.script_raised_destroy, on_destroyed, event_filter)
script.on_event(defines.events.on_entity_died, on_destroyed, event_filter)

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
    deregister_trackers(player.index)
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
    -- register_trackers(player.index, true)
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

script.on_event(defines.events.on_player_changed_surface, function (event)
  register_trackers(event.player_index, true)
end)

script.on_event(defines.events.on_tick, function (event)
  -- register trackers
  for player_index in pairs(game.connected_players) do
    if (event.tick + player_index) % math.floor(ticks_per_scan / subscans ^ 2) == 0 then
      register_trackers(player_index)
    end
  end
  -- update the size of each batch at the start of the loop so everything updates at the same rate
  if event.tick % ticks_per_update == 0 then
    storage.batch_size = math.ceil(storage.tracker_count / ticks_per_update)
    storage.last_index = nil
  end
  -- update trackers
  local old_trackers = {}
  local limit = (storage.last_index or event.tick % ticks_per_update == 0) and storage.batch_size or 0
  local i = 1
  while i <= limit do
    local index, tracker = next(storage.trackers, storage.last_index)
    if tracker and (not tracker.entity.valid or (event.tick - tracker.last_tick) > 2 * ticks_per_scan) then
      old_trackers[#old_trackers+1] = index
      if i == limit then i = limit - 1 end -- make sure we don't end on something thats going to be invalidated
    elseif tracker and next(tracker.players) then
      tracker.updates = (tracker.updates + 1) % checks_per_update
      update_render(tracker, tracker.updates == 0)
    end
    storage.last_index = index
    i = i + 1
  end
  -- remove old trackers
  for _, index in pairs(old_trackers) do
    storage.tracker_count = storage.tracker_count - 1
    local render = storage.trackers[index].render
    if render and render.valid then render.destroy() end
    storage.trackers[index] = nil
  end
end)

require("compatibility.scripts.FluidMustFlow")
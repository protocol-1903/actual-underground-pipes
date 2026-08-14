
-- The only thing we're doing is auto-join, so don't even bother if it's not enabled
if not script.active_mods["FluidMustFlow"] or not settings.startup["fmf-enable-duct-auto-join"].value then
  return
end

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

  for _, connection in pairs(entity.get_fluid_box_pipe_connections(1)) do
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
  
    if event.player_index then
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
  end
  if event.entity.name == "tomwub-duct-small" or event.entity.name == "tomwub-duct" then
    join_ducts(event)
  end
end
local event_filter = {{filter = "type", type = "pipe"}, {filter = "type", type = "storage-tank"}, {filter = "ghost_type", type = "pipe"}, {filter = "ghost_type", type = "storage-tank"}}
script.on_event(defines.events.on_built_entity, handle, event_filter)
script.on_event(defines.events.on_robot_built_entity, handle, event_filter)
script.on_event(defines.events.script_raised_built, handle, event_filter)
script.on_event(defines.events.script_raised_revive, handle, event_filter)
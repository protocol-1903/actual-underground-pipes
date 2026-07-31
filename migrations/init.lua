-- check if the mod has existed in the save before
if table_size(storage.tomwub) ~= 0 then return end

local migration_mode = settings.global["tomwub-migration-mode"].value
---@type {[string]: {direction: defines.direction, distance: uint, associated_pipe: data.PipeName}}
local underground_definitions = assert(prototypes.mod_data["the-one-mod-with-underground-bits"].data.underground_definitions)

game.print("[font=default-bold]WARNING:[/font] Actual Underground Pipes migration mode is set to " .. migration_mode .. ". If this is not intentional, change the migration setting and reload the save to apply migrations. [font=default-bold]THIS CANNOT BE DONE LATER![/font]")
game.print({"string-mod-setting-description.tomwub-migration-mode-" .. migration_mode})

if migration_mode == "off" then return end

if script.active_mods["parallel-piping"] then error("\n\n[font=default-bold]WARNING[/font]: Actual Underground Pipes cannot be added to a save at the same time as Parallel Piping! Please disable Parallel Piping, migrate the save, then install Parallel Piping.\n\n") end


local pins = {}
local solved = {}

for _, surface in pairs(game.surfaces) do
  for _, underground in pairs(surface.find_entities_filtered{type = "pipe-to-ground"}) do
    if not underground_definitions[underground.name] or underground.name == "underground-duct" or solved[underground.unit_number] then goto continue end
    local distance = underground_definitions[underground.name].distance
    local associated_pipe = underground_definitions[underground.name].associated_pipe
    local direction = underground_definitions[underground.name].direction
    local true_direction = (direction + underground.direction) % 16
    local position = underground.position
    local area = {
      {
        (true_direction == defines.direction.west and -math.floor(distance) - 0.4 or -0.4) + position.x,
        (true_direction == defines.direction.north and -math.floor(distance) - 0.4 or -0.4) + position.y
      },
      {
        (true_direction == defines.direction.east and math.floor(distance) + 0.4 or 0.4) + position.x,
        (true_direction == defines.direction.south and math.floor(distance) + 0.4 or 0.4) + position.y
      }
    }

    ---@type LuaEntity?
    local neighbour
    local current_distance
    for _, possible in pairs(surface.find_entities_filtered{
      type = settings.startup["npt-tomwub-weaving"].value and "pipe-to-ground" or nil,
      name = not settings.startup["npt-tomwub-weaving"].value and underground.name or nil,
      area = area
    }) do
      if (possible.direction + 8) % 16 == underground.direction then
        local test_distance = ((position.x - possible.position.x)^2 + (position.y - possible.position.y)^2)^0.5
        if not current_distance or current_distance > test_distance then
          current_distance = test_distance
          neighbour = possible
        end
      end
    end
    if not neighbour then goto continue end

    local positions = {}
    for i = 1, current_distance - 1 do
      positions[i] = {
        true_direction % 8 ~= 4 and position.x or position.x + i,
        true_direction % 8 ~= 0 and position.y or position.y + i,
      }
    end

    local last_valid
    for _, pos in pairs(positions) do
      local valid = true
      for dir, off in pairs{
        [0] = {0, 1},
        [4] = {-1, 0},
        [8] = {0, -1},
        [12] = {1, 0},
      } do
        if dir ~= true_direction or not last_valid then
          local check = {off[1] + pos[1], off[2] + pos[2]}
          if
            not ((check[1] == position.x and check[2] == position.y) or
            (check[1] == neighbour.position.x and check[2] == neighbour.position.y)) and
            surface.entity_prototype_collides(
              associated_pipe,
              {off[1] + pos[1], off[2] + pos[2]},
              false
          ) then
            valid = false
            break
          end
        end
      end
      last_valid = valid
      if valid and surface.can_place_entity{name = associated_pipe, position = pos} then
        surface.create_entity{
          name = associated_pipe,
          position = pos,
          force = underground.force,
          quality = underground.quality
        }
      elseif not valid then
        pins[#pins + 1] = {
          name = associated_pipe,
          pos = pos,
          surface = surface
        }
        if migration_mode == "unsafe" and surface.can_place_entity{name = associated_pipe, position = pos} then
          surface.create_entity{
            name = associated_pipe,
            position = pos,
            force = underground.force,
            quality = underground.quality
          }
          last_valid = true
        end
      end
    end

    solved[underground.unit_number] = true
    solved[neighbour.unit_number] = true

    ::continue::
  end
end

for _, player in pairs(game.players) do
  for _, pin in pairs(pins) do
    player.add_pin{
      label = migration_mode == "unsafe" and "WARNING: pipe conflict of " .. pin.name .. "found!" or "WARNING: possible pipe conflict of " .. pin.name .. " found!",
      position = pin.pos,
      surface = pin.surface
    }
  end
end
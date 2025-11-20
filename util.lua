xutil = xutil or {}
xutil.downshift = 10

xutil.reformat = function(spritesheet)
  for s, sprite in pairs(spritesheet) do
    if sprite.layers then
      for i, sprit in pairs(sprite.layers) do
        sprit.shift = util.by_pixel(0, xutil.downshift)
        if not s:find("visualization") then
          sprit.tint = {
            settings.startup["pipe-opacity"].value,
            settings.startup["pipe-opacity"].value,
            settings.startup["pipe-opacity"].value,
            settings.startup["pipe-opacity"].value
          }
        end
        if sprit.filename:sub(-10) == "shadow.png" then
          sprit.tint = {0, 0, 0, 0}
        end
      end
    elseif sprite.north then
      for _, direction in pairs{"north", "east", "south", "west"} do
        xutil.reformat(sprite[direction])
      end
    else
      sprite.shift = util.by_pixel(0, xutil.downshift)
      if not s:find("visualization") then
        sprite.tint = {
          settings.startup["pipe-opacity"].value,
          settings.startup["pipe-opacity"].value,
          settings.startup["pipe-opacity"].value,
          settings.startup["pipe-opacity"].value
        }
      end
    end
    if s:find("disabled_visualization") then
      sprite.filename = "__the-one-mod-with-underground-bits__/graphics/underground-disabled-visualization.png"
    elseif s:find("visualization") then
      sprite.filename = "__the-one-mod-with-underground-bits__/graphics/underground-visualization.png"
    end
  end
end

xutil.ptg_visualization = function(underground)
  return {
    north = {
      filename = underground and "__the-one-mod-with-underground-bits__/graphics/visualization.png" or "__base__/graphics/entity/pipe-to-ground/visualization.png",
      priority = "extra-high",
      x = 64,
      width = 64,
      height = 64,
      scale = 0.5,
      shift = underground and util.by_pixel(0, xutil.downshift) or nil,
      flags = {"icon"}
    },
    south = {
      filename = underground and "__the-one-mod-with-underground-bits__/graphics/visualization.png" or "__base__/graphics/entity/pipe-to-ground/visualization.png",
      priority = "extra-high",
      x = 192,
      width = 64,
      height = 64,
      scale = 0.5,
      shift = underground and util.by_pixel(0, xutil.downshift) or nil,
      flags = {"icon"}
    },
    west = {
      filename = underground and "__the-one-mod-with-underground-bits__/graphics/visualization.png" or "__base__/graphics/entity/pipe-to-ground/visualization.png",
      priority = "extra-high",
      x = 256,
      width = 64,
      height = 64,
      scale = 0.5,
      shift = underground and util.by_pixel(0, xutil.downshift) or nil,
      flags = {"icon"}
    },
    east = {
      filename = underground and "__the-one-mod-with-underground-bits__/graphics/visualization.png" or "__base__/graphics/entity/pipe-to-ground/visualization.png",
      priority = "extra-high",
      x = 128,
      width = 64,
      height = 64,
      scale = 0.5,
      shift = underground and util.by_pixel(0, xutil.downshift) or nil,
      flags = {"icon"}
    }
  }
end

xutil.ptg_visualizations = {
  north = {
    layers = {
      xutil.ptg_visualization(true).south,
      xutil.ptg_visualization().north,
    }
  },
  east = {
    layers = {
      xutil.ptg_visualization(true).west,
      xutil.ptg_visualization().east,
    }
  },
  south = {
    layers = {
      xutil.ptg_visualization(true).north,
      xutil.ptg_visualization().south,
    }
  },
  west = {
    layers = {
      xutil.ptg_visualization(true).east,
      xutil.ptg_visualization().west,
    }
  },
}

xutil.base_visualisation = {
  north = {layers = {
    xutil.ptg_visualization().north
  }},
  east = {layers = {
    xutil.ptg_visualization().east
  }},
  south = {layers = {
    xutil.ptg_visualization().south
  }},
  west = {layers = {
    xutil.ptg_visualization().west
  }},
}

xutil.dirmap = {
  [0] = "north",
  "east",
  "south",
  "west"
}

local recycling = mods["quality"] and require("__quality__.prototypes.recycling") or nil

xutil.adjust_recipes = function(u)
  -- if recipe exists
  if not mods["bztin"] then
    -- fix normal recipes
    for _, recipe in pairs{
      u,
      "casting-" .. u
    } do
      -- if recipe exists
      if data.raw.recipe[recipe] then
        -- just pipes, set to 2
        if #data.raw.recipe[recipe].ingredients == 1 and data.raw.recipe[recipe].ingredients[1].name:find("pipe") then
          data.raw.recipe[recipe].ingredients[1].amount = 2
        else -- not just pipes, get rid of them
          local ingredients = table.deepcopy(data.raw.recipe[recipe].ingredients)
          data.raw.recipe[recipe].ingredients = {}
          -- add ingredient if not the associated pipe
          for _, ingredient in pairs(ingredients) do
            if not ingredient.name:find("pipe") then
              data.raw.recipe[recipe].ingredients[#data.raw.recipe[recipe].ingredients+1] = ingredient
            end
          end
        end
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
  
  -- if recycling recipe exists
  if data.raw.recipe[u .. "-recycling"] and recycling then
    recycling.generate_recycling_recipe(data.raw.recipe[u])
  end
end

return xutil
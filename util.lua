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

return xutil
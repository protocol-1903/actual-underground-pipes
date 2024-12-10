-- generate default keybind to search for items
data:extend({
  {
    type = "custom-input",
    name = "widih-search-network",
    key_sequence = "ALT + Z",
    action = "lua",
    include_selected_prototype = true
  }
})
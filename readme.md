[![ko-fi](https://img.shields.io/badge/Ko--fi-Donate%20-hotpink?logo=kofi&logoColor=white&style=for-the-badge)](https://ko-fi.com/protocol1903) [![](https://img.shields.io/badge/dynamic/json?color=orange&label=Factorio&query=downloads_count&suffix=%20downloads&url=https%3A%2F%2Fmods.factorio.com%2Fapi%2Fmods%2Fthe-one-mod-with-underground-bits&style=for-the-badge)](https://mods.factorio.com/mod/the-one-mod-with-underground-bits) [![](https://img.shields.io/badge/Discord-Community-blue?style=for-the-badge)](https://discord.gg/K3fXMGVc4z) [![](https://img.shields.io/badge/Github-Source-green?style=for-the-badge)](https://github.com/protocol-1903/the-one-mod-with-underground-bits)

Got a cool base that uses my mod? Let me know and I can pics up on the mod portal!

*Advanced Fluid Handling, but... freehand*

*\- Ashierz*

Have you ever felt that piping things under buildings was too easy? That dragging a pipe to ground along was just... not fun?

Well no more! Now, with Actual Underground Pipes, you need to build the underground pipes! Using the same keybind for changing rail layer (default: ALT + G) change between aboveground and underground pipes! No extra items, no complex GUIs, no new recipes, just one keybind! *Note: pipes have been removed from pipe to ground recipes to compensate. No new items, recipes, or technologies are required; just press the keybind and any normal pipes in your inventory can be used as underground pipes.*

Underground pipes have the same restrictions as normal pipe to grounds. This means you can't build them across lava or space.

# WHERE IS THE BELT OPTION?
Unfortunately, do to the hardcoded nature of belts, they can't be done in the same manner underground pipes are done. It's possible, although difficult and implemented completely differently. If/when I get around to it, actual underground belts would be a separate mod. I have other larger mod's that I'm working on currently (including one similar to this, which will support belts) and those mods take precedence. I'll update this description when I have more news.

# TODO
- toggleable "alt mode" where a visualization is placed over underground pipes so they can be seen easier
- update logic to only mine the category that is in the player's hand

# Known Issues
- Pipe to Grounds have a phantom pipe cover when not connected. It's not fixable without removing the pipe covers of pipe to grounds entirely, and it only shows up when they aren't connected, so I don't see it as a major issue.
- Using the pipette tool on an underground pipe returns the non-underground variant. This is fixable eventually, but will require some major scripting and testing. Not planned as of now.
- There may be crashes or locale issues with certain mods. If you find them, please let me know.

# Compatibility
- [Fluid Must Flow](https://mods.factorio.com/mod/FluidMustFlow): Fluid Must Flow is fully compatible! Since v0.1.6, I have added full compatibility. There are some rough edges, but those will be fixed over time as I get player feedback on the changes.
- [Advanced Fluid Handling](https://mods.factorio.com/mod/underground-pipe-pack): Unfortunately, AUP does not have native compatibility with AFH. There's nothing that can be done in AUP to make it work, it would take some major rework of AFH scripting to make the two mods compatible. I don't see this as much of an issue, since both mods fill relatively similar roles. If it's brought up enough, something can probably be figured out.
- Supports all other mods, hopefully. If something doesn't work, let me know!

If you have a mod idea, let me know and I can look into it.
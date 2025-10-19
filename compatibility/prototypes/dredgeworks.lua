if not mods.dredgeworks then return end

-- allow seafloor pumps to connect to tomwub pipes
data.raw["mining-drill"]["seafloor-drill"].input_fluid_box.pipe_connections[1].connection_type = "underground"
data.raw["mining-drill"]["seafloor-drill"].input_fluid_box.pipe_connections[2].connection_type = "underground"
data.raw["mining-drill"]["seafloor-drill"].input_fluid_box.pipe_connections[3].connection_type = "underground"
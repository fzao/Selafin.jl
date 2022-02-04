using GLMakie
using Dates
using BenchmarkTools
using StatsBase
include("./Distance.jl")
include("./Utils.jl")
include("./Parameters.jl")
include("./Model.jl")
include("./Read.jl")
include("./Mesh.jl")
include("./Variables.jl")
using .Distance
using .Utils
using .Parameters
using .Model


# Selafin file
#filename = "malpasset.slf"
#filename = "mersey.slf"
#filename = "Alderney_sea_level.slf"
#filename = "Alderney.slf"
#filename = "girxl2d_result.slf"
filename = "a9.slf"

# read file
data = Read(filename);

# mesh quality
# qual = Quality(data, true);

# variable values
val = Get(data, 3, 1)

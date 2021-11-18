using GLMakie
using Dates
using BenchmarkTools
include("./Distance.jl")
include("./Utils.jl")
include("./Parameters.jl")
include("./Model.jl")
include("./Read.jl")
include("./Mesh.jl")
using .Distance
using .Utils
using .Parameters
using .Model


# read the Selafin file
#filename = "malpasset.slf"
#filename = "mersey.slf"
#filename = "Alderney_sea_level.slf"
filename = "Alderney.slf"
filename = "girxl2d_result.slf"
filename = "a9.slf"
data = Read(filename)

# mesh Quality
qual = Quality(data)

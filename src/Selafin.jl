#
# Selafin.jl : a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language
#
# Released under the MIT License
#
# Copyright (c) 2021 Fabrice Zaoui
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE
#
module Selafin

    # external dependencies
    using Dates
    using GeometryBasics
    using GLMakie
    using StatsBase
    using FFMPEG_jll

    # local functions and modules
    include("./Distance.jl")
    include("./Utils.jl")
    include("./Parameters.jl")
    include("./Model.jl")
    include("./Read.jl")
    include("./Mesh.jl")
    include("./Variables.jl")
    include("./Plot1D.jl")
    include("./Plot2D.jl")
    include("./Plot3D.jl")
    include("./PlotField.jl")
    include("./Histogram.jl")
    include("./Extrema.jl")
    include("./Correlation.jl")
    include("./Statistics.jl")
    using .Distance
    using .Utils
    using .Parameters
    using .Model

    GLMakie.activate!()
end # module

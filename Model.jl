
# Model.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# The Julia structure of the Telemac parameters
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
module Model

    export Data

    mutable struct Data
        markposition::Int64  # marker position for the values of variables
        filename:: String  # Selafin file path
        title::String  # name of the study
        nbvars::Int32  # number of variables
        nblayers::Int32  # number of layers
        nbtriangles::Int32  # number of mesh triangles
        nbnodes::Int32  # number of mesh nodes
        nbsteps::Int32  # number of time steps
        timestep::Int32  # time step in seconds
        varnames  # names of variables
        typefloat  # simple or double precision
        iparam::Array{Int32, 1}  # integer parameters
        idate::Array{Int32, 1}  # date info
        ikle::Array{Int32, 2}  # mesh connectivity
        x::Array{Float64, 1}  # mesh x-coordinates
        y::Array{Float64, 1}  # mesh y-coordinates

        Data() = new()
    end

end

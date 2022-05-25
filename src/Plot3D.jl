# Plot3D.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# 2D interactive plot with GLMakie
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
function Plot3D(data, warpcoef = 1.)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end

    numbot = 0
    for i in 1:data.nbvars
        if data.varnames[i][1:4] == "BOTT" || data.varnames[i][1:4] == "FOND"
            numbot = i
            break
        end
    end
    if numbot == 0
        println("$(Parameters.noksymbol) No bottom elevation found in data")
        return
    else
        z = Selafin.Get(data, numbot, 1, 1)
        z = warpcoef * z
    end

    # figure
    print("$(Parameters.hand) Pending GPU-powered 3D plot... (this may take a while)")
    flush(stdout)
    nodes = [Point3f0(data.x[i], data.y[i], z[i]) for i in 1:data.nbnodesLayer]
    tris = data.ikle[1:data.nbtrianglesLayer, 1:3]
    tri = [GLTriangleFace(tris[i, 1], tris[i, 2], tris[i, 3]) for i in 1:data.nbtrianglesLayer]
    mesh(nodes, tri, color=last.(nodes), figure = (resolution = (1280, 1024),)) |> display

    println("\r$(Parameters.oksymbol) Succeeded!                                                  ")

    return nothing
end

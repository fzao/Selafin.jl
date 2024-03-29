# Variables.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# Read an array of Telemac results based on a variable number, a time step number and a number of layer (T3D)
# Optionally displays (figopt parameter) and prints out (figname parameter) the results
# Return the real values if succeed
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
"""
    Get(data, novar, notime, noplane, [figopt, figname])

    Return all the mesh values of a given variable
    
    # Arguments
        - `data::Struct`: Selafin file information provided by the Read(filename) function
        - `novar::Int`: The variable number (default: 0)
        - `notime::Int`: The time step number (default: 0)
        - `noplane::Int`: The layer number (default: 1)
        - `figopt::Bool`: Optional parameter for plotting (default: false)
        - `figname::String`: Optional parameter for the file name of the plot saved on drive (default: nothing)
"""
function Get(data, novar=0, notime=0, noplane=1, figopt=false, figname=nothing)

    if typeof(data) != Data
        if data.verbose == true println("$(Parameters.noksymbol) Parameter is not a Data struct") end
        return
    end
    if novar <= 0
        if data.verbose == true println("$(Parameters.noksymbol) The variable number is not positive") end
        return
    elseif novar > data.nbvars
        if data.verbose == true println("$(Parameters.noksymbol) The variable number exceeds the number of recorded variables") end
        return
    end
    if notime <= 0
        if data.verbose == true println("$(Parameters.noksymbol) The time number is not positive") end
        return
    elseif notime > data.nbsteps
        if data.verbose == true println("$(Parameters.noksymbol) The time number exceeds the number of records") end
        return
    end
    if noplane < 1
        if data.verbose == true println("$(Parameters.noksymbol) The layer number is not positive") end
        return
    end
    if noplane > data.nblayers
        if data.verbose == true println("$(Parameters.noksymbol) The layer number exceeds the max value") end
        return
    end

    fid = open(data.filename, "r")
    seek(fid, data.markposition)

    variables = Array{data.typefloat, 1}(undef, data.nbnodesLayer * data.nblayers)
    timevalue =  Array{Float32, 1}(undef, data.nbsteps)
    exitloop = false
    for t in 1:data.nbsteps
        recloc = ntoh(read(fid, Int32))
        timevalue[t] = ntoh(read(fid, Float32))
        recloc = ntoh(read(fid, Int32))
        for v in 1:data.nbvars
            recloc = ntoh(read(fid, Int32))
            raw_data = zeros(UInt8, recloc)
            readbytes!(fid, raw_data, recloc)
            variables[:] .= ntoh.(reinterpret(data.typefloat, raw_data))
            recloc = ntoh(read(fid, Int32))
            if t == notime && v == novar
                exitloop = true
                break
            end
        end
        if exitloop
            break
        end
    end

    # close the Selafin file
    close(fid)

    # reshape and extract
    values = reshape(variables, data.nbnodesLayer, data.nblayers)
    variables = values[:, noplane]

    # statistics
    minval = round(minimum(variables), digits = 2)
    meanval = round(mean(variables), digits = 2)
    medval = round(median(variables), digits = 2)
    maxval = round(maximum(variables), digits = 2)
    varname = lstrip(rstrip(data.varnames[novar]))
    timesec = (notime - 1) * data.timestep
    strtime = convertSeconds(timesec)
    if data.verbose == true
        println("$(Parameters.oksymbol) Read variable #$(novar) ($(varname)) at time record #$(notime) ($(strtime) elapsed) for the layer #$(noplane) with:")
        println("\t Min. value: $minval")
        println("\t Max. value: $maxval")
        println("\t Mean: $meanval")
        println("\t Median: $medval")
    end

    if figopt
        fig = Figure(size = (1280, 1024))
        Axis(fig[1, 1], title=data.varnames[novar]*" TIME($(strtime)) "*" NB_LAYER($(noplane)) ", xlabel = "x-coordinates (m)", ylabel = "y-coordinates (m)")
        maxvar = maximum(variables)
        minvar = minimum(variables)
        if minvar == maxvar
            maxvar = minvar + Parameters.eps
        end
        Colorbar(fig[1, 2], limits = (minvar, maxvar), colormap = :viridis)
        mesh!([data.x[1:data.nbnodesLayer] data.y[1:data.nbnodesLayer]], data.ikle[1:data.nbtrianglesLayer, 1:3], color=variables, colormap=:viridis, shading=NoShading)

        if !isnothing(figname)
            save(figname, fig, px_per_unit = 2)
        end

        display(fig)
    end

    return variables
end

"""
GetAllTime(data, novar, noplane)

    Return all the mesh values of a given variable, for all the time steps
    
    # Arguments
        - `data::Struct`: Selafin file information provided by the Read(filename) function
        - `novar::Int`: The variable number (default: 0)
        - `noplane::Int`: The layer number (default: 1)
"""
function GetAllTime(data, novar=0, noplane=1)
    if typeof(data) != Data
        if data.verbose == true println("$(Parameters.noksymbol) Parameter is not a Data struct") end
        return
    end
    if novar <= 0
        if data.verbose == true println("$(Parameters.noksymbol) The variable number is not positive") end
        return
    elseif novar > data.nbvars
        if data.verbose == true println("$(Parameters.noksymbol) The variable number exceeds the number of recorded variables") end
        return
    end
    if noplane < 1
        if data.verbose == true println("$(Parameters.noksymbol) The layer number is not positive") end
        return
    end
    if noplane > data.nblayers
        if data.verbose == true println("$(Parameters.noksymbol) The layer number exceeds the max value") end
        return
    end

    fid = open(data.filename, "r")
    seek(fid, data.markposition)

    variables = Array{data.typefloat, 1}(undef, data.nbnodesLayer * data.nblayers)
    varalltime = Array{data.typefloat, 2}(undef, data.nbsteps, data.nbnodesLayer)
    timevalue =  Array{Float32, 1}(undef, data.nbsteps)
    for t in 1:data.nbsteps
        recloc = ntoh(read(fid, Int32))
        timevalue[t] = ntoh(read(fid, Float32))
        recloc = ntoh(read(fid, Int32))
        for v in 1:data.nbvars
            recloc = ntoh(read(fid, Int32))
            raw_data = zeros(UInt8, recloc)
            readbytes!(fid, raw_data, recloc)
            variables[:] .= ntoh.(reinterpret(data.typefloat, raw_data))
            recloc = ntoh(read(fid, Int32))
            if v == novar
                # reshape and extract
                varalltime[t, :] = reshape(variables, data.nbnodesLayer, data.nblayers)[:, noplane]
            end
        end
    end

    # close the Selafin file
    close(fid)

    return varalltime
end

"""
    GetNode(data, node, novar, notime)

    Return the node value of a given variable
    
    # Arguments
        - `data::Struct`: Selafin file information provided by the Read(filename) function
        - `node::Int`: The global node number (default: 0)
        - `novar::Int`: The variable number (default: 0)
        - `notime::Int`: The time step number (default: 0)
"""
function GetNode(data, node = 0, novar=0, notime=0)

    if typeof(data) != Data
        if data.verbose == true println("$(Parameters.noksymbol) Parameter is not a Data struct") end
        return
    end
    if novar <= 0
        if data.verbose == true println("$(Parameters.noksymbol) The variable number is not positive") end
        return
    elseif novar > data.nbvars
        if data.verbose == true println("$(Parameters.noksymbol) The variable number exceeds the number of recorded variables") end
        return
    end
    if notime <= 0
        if data.verbose == true println("$(Parameters.noksymbol) The time number is not positive") end
        return
    elseif notime > data.nbsteps
        if data.verbose == true println("$(Parameters.noksymbol) The time number exceeds the number of records") end
        return
    end
    if node < 1
        if data.verbose == true println("$(Parameters.noksymbol) The node number is not positive") end
        return
    elseif node > data.nbnodes
        if data.verbose == true println("$(Parameters.noksymbol) The node number exceeds the max value") end
        return
    end

    noplane, nodenum = findnum(data, node)
    res = Selafin.Get(data, novar, notime, noplane)

    return res[nodenum]
end

"""
    GetNodeAllTime(data, node, novar)

    Return the node value of a given variable for all the time steps
    
    # Arguments
        - `data::Struct`: Selafin file information provided by the Read(filename) function
        - `node::Int`: The global node number (default: 0)
        - `novar::Int`: The variable number (default: 0)
"""
function GetNodeAllTime(data, node = 0, novar=0)

    if typeof(data) != Data
        if data.verbose == true println("$(Parameters.noksymbol) Parameter is not a Data struct") end
        return
    end
    if novar <= 0
        if data.verbose == true println("$(Parameters.noksymbol) The variable number is not positive") end
        return
    elseif novar > data.nbvars
        if data.verbose == true println("$(Parameters.noksymbol) The variable number exceeds the number of recorded variables") end
        return
    end
    if node < 1
        if data.verbose == true println("$(Parameters.noksymbol) The node number is not positive") end
        return
    elseif node > data.nbnodes
        if data.verbose == true println("$(Parameters.noksymbol) The node number exceeds the max value") end
        return
    end

    noplane, nodenum = findnum(data, node)
    res = Selafin.GetAllTime(data, novar, noplane)

    return res[:, nodenum]
end

"""
    GetXY(data, X, Y, novar, notime, noplane)

    Return the value of a given variable from 2D and layer coordinates
    
    # Arguments
        - `data::Struct`: Selafin file information provided by the Read(filename) function
        - `X::Float`: x-coordinate
        - `Y::Float`: y-coordinate
        - `novar::Int`: The variable number (default: 0)
        - `notime::Int`: The time step number (default: 0)
        - `noplane::Int`: The layer number (default: 1)
"""
function GetXY(data, X, Y, novar=0, notime=0, noplane=1)

    if typeof(data) != Data
        if data.verbose == true println("$(Parameters.noksymbol) Parameter is not a Data struct") end
        return
    end
    if novar <= 0
        if data.verbose == true println("$(Parameters.noksymbol) The variable number is not positive") end
        return
    elseif novar > data.nbvars
        if data.verbose == true println("$(Parameters.noksymbol) The variable number exceeds the number of recorded variables") end
        return
    end
    if notime <= 0
        if data.verbose == true println("$(Parameters.noksymbol) The time number is not positive") end
        return
    elseif notime > data.nbsteps
        if data.verbose == true println("$(Parameters.noksymbol) The time number exceeds the number of records") end
        return
    end
    if noplane < 1
        if data.verbose == true println("$(Parameters.noksymbol) The layer number is not positive") end
        return
    end
    if noplane > data.nblayers
        if data.verbose == true println("$(Parameters.noksymbol) The layer number exceeds the max value") end
        return
    end

    # get the triangle number of layer #1 (xy-coordinates are the same, whatever the layer number)
    triangle = interiorTriangle(data, X, Y)
    if isnothing(triangle)
        if data.verbose == true println("$(Parameters.noksymbol) xy-coordinates not found") end
        return nothing
    end

    # get all the mesh values
    values = Selafin.Get(data, novar, notime, noplane)

    # select the surrounding points and interpolate (triangles ordering is the same, whatever the layer number)
    A = data.ikle[triangle, 1]; B = data.ikle[triangle, 2]; C = data.ikle[triangle, 3]
    valA = values[A]; valB = values[B]; valC = values[C]
    valinterp = interpolInTriangle(data, A, B, C, valA, valB, valC, [X, Y])

    return valinterp

end

"""
    GetXYAllTime(data, X, Y, novar, noplane)

    Return the value of a given variable from 2D and layer coordinates
    
    # Arguments
        - `data::Struct`: Selafin file information provided by the Read(filename) function
        - `X::Float`: x-coordinate
        - `Y::Float`: y-coordinate
        - `novar::Int`: The variable number (default: 0)
        - `noplane::Int`: The layer number (default: 1)
"""
function GetXYAllTime(data, X, Y, novar=0, noplane=1)

    if typeof(data) != Data
        if data.verbose == true println("$(Parameters.noksymbol) Parameter is not a Data struct") end
        return
    end
    if novar <= 0
        if data.verbose == true println("$(Parameters.noksymbol) The variable number is not positive") end
        return
    elseif novar > data.nbvars
        if data.verbose == true println("$(Parameters.noksymbol) The variable number exceeds the number of recorded variables") end
        return
    end
    if noplane < 1
        if data.verbose == true println("$(Parameters.noksymbol) The layer number is not positive") end
        return
    end
    if noplane > data.nblayers
        if data.verbose == true println("$(Parameters.noksymbol) The layer number exceeds the max value") end
        return
    end

    # get the triangle number of layer #1 (xy-coordinates are the same, whatever the layer number)
    triangle = interiorTriangle(data, X, Y)
    if isnothing(triangle)
        if data.verbose == true println("$(Parameters.noksymbol) xy-coordinates not found") end
        return nothing
    end

    # get all the mesh values for all the times
    values = Selafin.GetAllTime(data, novar, noplane)

    # select the surrounding points and interpolate (triangles ordering is the same, whatever the layer number)
    A = data.ikle[triangle, 1]; B = data.ikle[triangle, 2]; C = data.ikle[triangle, 3]

    # interpolate for each time value
    valinterp = []
    for t in 1:data.nbsteps
        valA = values[t, A]; valB = values[t, B]; valC = values[t, C]
        push!(valinterp, interpolInTriangle(data, A, B, C, valA, valB, valC, [X, Y]))
    end

    return Float64.(valinterp)

end

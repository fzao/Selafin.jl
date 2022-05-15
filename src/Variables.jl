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
function Get(data, novar=0, notime=0, noplane=1, figopt=false, figname=nothing)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end
    if novar <= 0
        println("$(Parameters.noksymbol) The variable number is not positive")
        return
    elseif novar > data.nbvars
        println("$(Parameters.noksymbol) The variable number exceeds the number of recorded variables")
        return
    end
    if notime <= 0
        println("$(Parameters.noksymbol) The time number is not positive")
        return
    elseif notime > data.nbsteps
        println("$(Parameters.noksymbol) The time number exceeds the number of records")
        return
    end
    if noplane < 1
        println("$(Parameters.noksymbol) The layer number is not positive")
        return
    end
    if noplane > data.nblayers
        println("$(Parameters.noksymbol) The layer number exceeds the max value")
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
    println("$(Parameters.oksymbol) Read variable #$(novar) ($(varname)) at time record #$(notime) ($(strtime) elapsed) with:")
    println("\t Min. value: $minval")
    println("\t Max. value: $maxval")
    println("\t Mean: $meanval")
    println("\t Median: $medval")

    if figopt
        fig = Figure()
        Axis(fig[1, 1], title=data.varnames[novar]*" TIME($(strtime)) "*" NB_LAYER($(noplane)) ", xlabel = "x-coordinates (m)", ylabel = "y-coordinates (m)")
        maxvar = maximum(variables)
        minvar = minimum(variables)
        if minvar == maxvar
            maxvar = minvar + Parameters.eps
        end
        Colorbar(fig[1, 2], limits = (minvar, maxvar), colormap = :viridis)
        mesh([data.x[1:data.nbnodesLayer] data.y[1:data.nbnodesLayer]], data.ikle[1:data.nbtrianglesLayer, 1:3], color=variables, colormap=:viridis, shading=false)

        if !isnothing(figname)
            save(figname, fig, px_per_unit = 2)
        end

        display(fig)
    end

    return variables
end

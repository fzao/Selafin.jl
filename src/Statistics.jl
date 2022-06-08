# Statistics.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# Min, Max, Mean, and Median calculations
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
function Statistics(data)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end

    # observables and initialization
    varnumber = Observable(1)
    layernumber = Observable(1)
    print("$(Parameters.hand) Memory caching...")
    flush(stdout)
    allvalues = Observable(Selafin.GetAllTime(data, 1, 1))
    println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
    x = range(1.0, data.nbsteps)
    y1 = @lift(vec(minimum($(allvalues), dims = 2)))
    y2 = @lift(vec(maximum($(allvalues), dims = 2)))
    y3 = @lift(vec(mean($(allvalues), dims = 2)))
    y4 = @lift(vec(median($(allvalues), dims = 2)))

    # figure
    print("$(Parameters.hand) Pending GPU-powered 2D plot... (this may take a while)")
    flush(stdout)
    fig = Figure(resolution = (1280, 1024))
    ax1 = Axis(fig[1, 1], xlabel = "Time step number", ylabel = "Min")
    ax2 = Axis(fig[1, 2], xlabel = "Time step number", ylabel = "Max")
    ax3 = Axis(fig[2, 1], xlabel = "Time step number", ylabel = "Mean")
    ax4 = Axis(fig[2, 2], xlabel = "Time step number", ylabel = "Median")

    function setAxisLimits()
        if data.nbsteps == 1
            xmin = 0
            xmax = 2
        else
            xmin = 1
            xmax = data.nbsteps + 1
        end
        y1min = minimum(minimum(allvalues[], dims=2)) - 0.1 * abs(minimum(minimum(allvalues[], dims=2)))
        y1max = maximum(minimum(allvalues[], dims=2)) + 0.1 * abs(maximum(minimum(allvalues[], dims=2)))
        if y1min ≈ y1max  # zero
            y1min = -1e6
            y1max = 1e6
        end
        limits!(ax1, xmin, xmax, y1min, y1max)
        y2min = minimum(maximum(allvalues[], dims=2)) - 0.1 * abs(minimum(maximum(allvalues[], dims=2)))
        y2max = maximum(maximum(allvalues[], dims=2)) + 0.1 * abs(maximum(maximum(allvalues[], dims=2)))
        if y2min ≈ y2max  # zero
            y2min = -1e6
            y2max = 1e6
        end
        limits!(ax2, xmin, xmax, y2min, y2max)
        y3min = minimum(mean(allvalues[], dims=2)) - 0.1 * abs(minimum(mean(allvalues[], dims=2)))
        y3max = maximum(mean(allvalues[], dims=2)) + 0.1 * abs(maximum(mean(allvalues[], dims=2)))
        if y3min ≈ y3max  # zero
            y3min = -1e6
            y3max = 1e6
        end
        limits!(ax3, xmin, xmax, y3min, y3max)
        y4min = minimum(median(allvalues[], dims=2)) - 0.1 * abs(minimum(median(allvalues[], dims=2)))
        y4max = maximum(median(allvalues[], dims=2)) + 0.1 * abs(maximum(median(allvalues[], dims=2)))
        if y4min ≈ y4max  # zero
            y4min = -1e6
            y4max = 1e6
        end
        limits!(ax4, xmin, xmax, y4min, y4max)
    end

    scatter!(fig[1, 1], x, y1)
    scatter!(fig[1, 2], x, y2)
    scatter!(fig[2, 1], x, y3)
    scatter!(fig[2, 2], x, y4)

    # menu (variable number)
    varchoice = Menu(fig[3,1], prompt = "Variable:", options = data.varnames, i_selected = 1)
    on(varchoice.selection) do selected_variable
        varnumber[] = findall(occursin.(selected_variable, data.varnames))[1]
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        allvalues[] = Selafin.GetAllTime(data, varnumber.val, layernumber.val)
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
        setAxisLimits()
    end

    # menu (layer number)
    layerchoice = Menu(fig[3, 2], prompt = "Variable:", options = 1:data.nblayers, i_selected = 1)
    on(layerchoice.selection) do selected_layer
        layernumber[] = selected_layer
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        allvalues[] = Selafin.GetAllTime(data, varnumber.val, layernumber.val)
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
        setAxisLimits()
    end

    # button (save figure)
    savefig = Button(fig[3, 3], label="Save Figure")

#=     # save figure on button click
    on(savefig.clicks) do clicks
        newfig = Figure(resolution = (1280, 1024))
        strtime = convertSeconds((timenumber.val - 1) * data.timestep)
        Axis(newfig[1, 1], title=data.varnames[varnumber.val]*" TIME($(strtime)) "*" NB_LAYER($(layernumber.val)) ", xlabel = "x-coordinates (m)", ylabel = "y-coordinates (m)")
        mesh!([data.x[1:data.nbnodesLayer] data.y[1:data.nbnodesLayer]], data.ikle[1:data.nbtrianglesLayer, 1:3], color=values, colormap=colorschoice, shading=false)
        maxvar = maximum(values.val)
        minvar = minimum(values.val)
        if minvar == maxvar
            maxvar = minvar + Parameters.eps
        end
        Colorbar(newfig[1, 2], limits = (minvar, maxvar), colormap = colorschoice)
        figname = "Selafin Plot2D "*replace(replace(string(Dates.now()), 'T' => " at "), ':' => '.')*".png"
        save(figname, newfig, px_per_unit = 2)
        println("$(Parameters.oksymbol) Figure saved")
        display(fig)
    end =#

    display(fig)
    println("\r$(Parameters.oksymbol) Succeeded!                                                  ")

    return nothing
end

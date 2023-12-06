# Correlation.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# 2D interactive scatter plot: variable1 = f(variable2)
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
    Correlation(data)

    Time-dependent correlation between the Telemac variables

    Use of the scatter() Makie function
    
    # Arguments
        - `data::Struct`: Selafin file information provided by the Read(filename) function
"""
function Correlation(data)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end

    # observables
    print("$(Parameters.hand) Memory caching...")
    flush(stdout)
    allvalues1 = Observable(Selafin.GetAllTime(data, 1, 1))
    allvalues2 = Observable(Selafin.GetAllTime(data, 1, 1))
    println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
    values1 = Observable(allvalues1[][1, :])
    values2 = Observable(allvalues2[][1, :])
    varnumber1 = Observable(1)
    varnumber2 = Observable(1)
    layernumber = Observable(1)
    timenumber = Observable(1)

    # figure
    print("$(Parameters.hand) Pending GPU-powered 2D plot... (this may take a while)")
    flush(stdout)
    GLMakie.closeall()
    fig = Figure(size = (1280, 1024))
    ax = Axis(fig[1, 1])
    ax.xlabel = data.varnames[1]
    ax.ylabel = data.varnames[1]
    xmin = minimum(allvalues1.val)
    xmin = xmin >= 0. ? 0.95 * xmin : 1.05 * xmin
    xmax = maximum(allvalues1.val)
    xmax = xmax >= 0. ? 1.05 * xmax : 0.95 * xmax
    ymin = minimum(allvalues2.val)
    ymin = ymin >= 0. ? 0.95 * ymin : 1.05 * ymin
    ymax = maximum(allvalues2.val)
    ymax = ymax >= 0. ? 1.05 * ymax : 0.95 * ymax
    xlims!(ax, xmin, xmax)
    ylims!(ax, ymin, ymax)
    scatter!(values1, values2)

    # slider (time step)
    time_slider = SliderGrid(fig[2, 1], (label = "Time step number", range = 1:1:data.nbsteps, startvalue = 1))
    on(time_slider.sliders[1].value) do timeval
        values1[] = allvalues1[][timeval, :]
        values2[] = allvalues2[][timeval, :]
        println("$(Parameters.triright) Pearson correlation: " * string(cor(values1.val, values2.val)))
        timenumber[] = timeval
    end

    # menu (variable number #1)
    varchoice1 = Menu(fig, options = data.varnames, i_selected = 1)
    on(varchoice1.selection) do selected_variable1
        varnumber1[] = findall(occursin.(selected_variable1, data.varnames))[1]
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        allvalues1[] = Selafin.GetAllTime(data, varnumber1.val, layernumber.val)
        ax.xlabel = data.varnames[varnumber1.val]
        xmin = minimum(allvalues1.val)
        xmin = xmin >= 0. ? 0.95 * xmin : 1.05 * xmin
        xmax = maximum(allvalues1.val)
        xmax = xmax >= 0. ? 1.05 * xmax : 0.95 * xmax
        xlims!(ax, xmin, xmax)
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
        values1[] = allvalues1[][timenumber.val, :]
        println("$(Parameters.triright) Pearson correlation: " * string(cor(values1.val, values2.val)))
    end

    # menu (variable number #2)
    varchoice2 = Menu(fig, options = data.varnames, i_selected = 1)
    on(varchoice2.selection) do selected_variable2
        varnumber2[] = findall(occursin.(selected_variable2, data.varnames))[1]
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        allvalues2[] = Selafin.GetAllTime(data, varnumber2.val, layernumber.val)
        ax.ylabel = data.varnames[varnumber2.val]
        ymin = minimum(allvalues2.val)
        ymin = ymin >= 0. ? 0.95 * ymin : 1.05 * ymin
        ymax = maximum(allvalues2.val)
        ymax = ymax >= 0. ? 1.05 * ymax : 0.95 * ymax
        ylims!(ax, ymin, ymax)
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
        values2[] = allvalues2[][timenumber.val, :]
        println("$(Parameters.triright) Pearson correlation: " * string(cor(values1.val, values2.val)))
    end

    # menu (layer number)
    layerchoice = Menu(fig, options = 1:data.nblayers, i_selected = 1)
    on(layerchoice.selection) do selected_layer
        layernumber[] = selected_layer
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        allvalues1[] = Selafin.GetAllTime(data, varnumber1.val, layernumber.val)
        allvalues2[] = Selafin.GetAllTime(data, varnumber2.val, layernumber.val)
        xmin = minimum(allvalues1.val)
        xmin = xmin >= 0. ? 0.95 * xmin : 1.05 * xmin
        xmax = maximum(allvalues1.val)
        xmax = xmax >= 0. ? 1.05 * xmax : 0.95 * xmax
        ymin = minimum(allvalues2.val)
        ymin = ymin >= 0. ? 0.95 * ymin : 1.05 * ymin
        ymax = maximum(allvalues2.val)
        ymax = ymax >= 0. ? 1.05 * ymax : 0.95 * ymax
        xlims!(ax, xmin, xmax)
        ylims!(ax, ymin, ymax)
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
        values1[] = allvalues1[][timenumber.val, :]
        values2[] = allvalues2[][timenumber.val, :]
        println("$(Parameters.triright) Pearson correlation: " * string(cor(values1.val, values2.val)))
    end

    # button (save figure)
    savefig = Button(fig, label="Save Figure")
    # save figure on button click
    on(savefig.clicks) do clicks
        newfig = Figure(size = (1280, 1024))
        strtime = convertSeconds((timenumber.val - 1) * data.timestep)
        a, b = linearreg(values1.val, values2.val)
        Axis(newfig[1, 1], title=" TIME($(strtime))  "*" NB_LAYER($(layernumber.val))  "*" R = "*string(cor(values1.val, values2.val))*"       Y = $(a) $(Parameters.bigtimes) X + $(b)", xlabel = data.varnames[varnumber1.val], ylabel = data.varnames[varnumber2.val])
        scatter!(values1, values2)
        xmin = minimum(values1.val)
        xmax = maximum(values1.val)
        ymin = a * xmin + b
        ymax = a * xmax + b
        println("$(Parameters.triright) Linear regression: Y = $(a) $(Parameters.bigtimes) X + $(b)")
        lines!([xmin, xmax], [ymin, ymax], color = :gold)
        figname = "Selafin Correlation "*replace(replace(string(Dates.now()), 'T' => " at "), ':' => '.')*".png"
        save(figname, newfig, px_per_unit = 2)
        println("$(Parameters.oksymbol) Figure saved")
        display(fig)
    end

    # layout
    fig[3,1] = hgrid!(
        Label(fig, "Variable #2:"), varchoice2,
        Label(fig, "Variable #1:"), varchoice1,
        Label(fig, "Layer:"), layerchoice,
        savefig
    )

    display(fig)
    println("\r$(Parameters.oksymbol) Succeeded!                                                  ")

    return nothing
end

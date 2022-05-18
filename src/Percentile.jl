# Percentile.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# Percentile interactive plot with GLMakie
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
function Percentile(data)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end

    # observables
    varnumber = Observable(1)
    layernumber = Observable(1)
    timenumber = Observable(1)
    colorschoice = Observable(:viridis)
    threshold = Observable(5)
    comparison = Observable('≥')

     # initialization
    x = data.x[1:data.nbnodesLayer]
    y = data.y[1:data.nbnodesLayer]
    values = Selafin.Get(data,1,1,1)
    xp = x
    yp = y
    valp = values

    # mask
    function updatemask()
        pval = percentile(values, threshold.val)
        if comparison.val == '≥'
             mask = values .>= pval
        else
             mask = values .<= pval
        end
        xp = x[mask]
        yp = y[mask]
        valp = values[mask]
    end

    # figure
    print("$(Parameters.hand) Pending GPU-powered 2D plot... (this may take a while)")
    flush(stdout)
    fig = Figure(resolution = (1280, 1024))
    Axis(fig[1, 1], xlabel = "xcoordinates (m)", ylabel = "ycoordinates (m)")
    Colorbar(fig[1, 2], label = "Normalized values", colormap = colorschoice)
    updatemask()
    scatter!(xp, yp, color = valp, colormap = colorschoice)
    
    # slider (time step)
    time_slider = SliderGrid(fig[2, 1], (label = "Time step number", range = 1:1:data.nbsteps, startvalue = 1))
    on(time_slider.sliders[1].value) do timeval
        values = Selafin.Get(data, varnumber.val, timeval, layernumber.val)
        updatemask()
        timenumber[] = timeval
    end
    
    # menu (variable number)
    varchoice = Menu(fig, options = data.varnames, i_selected = 1)
    on(varchoice.selection) do selected_variable
        varnumber[] = findall(occursin.(selected_variable, data.varnames))[1]
        values = Selafin.Get(data,varnumber.val, timenumber.val, layernumber.val)
        updatemask()
    end
    
    # menu (layer number)
    layerchoice = Menu(fig, options = 1:data.nblayers, i_selected = 1)
    on(layerchoice.selection) do selected_layer
        layernumber[] = selected_layer
        values[] = Selafin.Get(data,varnumber.val, timenumber.val, layernumber.val)
        updatemask()
    end
    
    # menu (colorscheme)
    colorchoice = Menu(fig, options = Parameters.scientific, i_selected = 25)
    on(colorchoice.selection) do selected_color
        colorschoice[] = selected_color
    end
    
    # button (save figure)
    savefig = Button(fig, label="Save Figure")

    # layout
    fig[3,1] = hgrid!(
        Label(fig, "Variable:"), varchoice,
        Label(fig, "Layer:"), layerchoice,
        Label(fig, "Colors:"), colorchoice,
        savefig
    )

    # menu (comparison operator)
    compare = Menu(fig, options = [Parameters.ge, Parameters.le], i_selected = 1)
    on(compare.selection) do selected_compare
        #varnumber[] = findall(occursin.(selected_variable, data.varnames))[1]
        #values[] = Selafin.Get(data,varnumber.val, timenumber.val, 1)
    end

    # slider (percentile)
    percentile_slider = SliderGrid(fig[2, 1], (label = "Percentile", range = 5:5:95, startvalue = 1))
    on(percentile_slider.sliders[1].value) do percentile
        #values[] = Selafin.Get(data, varnumber.val, timeval, layernumber.val)
        #timenumber[] = timeval
    end

    # layout
    fig[4,1] = hgrid!(
        Label(fig, "Variable:"), compare,
        Label(fig, "Layer:"), percentile_slider
    )

    # save figure on button click
    # on(savefig.clicks) do clicks
    #     newfig = Figure(resolution = (1280, 1024))
    #     strtime = convertSeconds((timenumber.val  1) * data.timestep)
    #     Axis(newfig[1, 1], title=data.varnames[varnumber.val]*" TIME($(strtime)) "*" NB_LAYER($(layernumber.val)) ", xlabel = "xcoordinates (m)", ylabel = "ycoordinates (m)")
    #     mesh!([data.x[1:data.nbnodesLayer] data.y[1:data.nbnodesLayer]], data.ikle[1:data.nbtrianglesLayer, 1:3], color=values, colormap=colorschoice, shading=false)
    #     maxvar = maximum(values.val)
    #     minvar = minimum(values.val)
    #     if minvar == maxvar
    #         maxvar = minvar + Parameters.eps
    #     end
    #     Colorbar(newfig[1, 2], limits = (minvar, maxvar), colormap = colorschoice)
    #     figname = "Selafin Plot2D "*replace(replace(string(Dates.now()), 'T' => " at "), ':' => '.')*".png"
    #     save(figname, newfig, px_per_unit = 2)
    #     println("$(Parameters.oksymbol) Figure saved")
    #     display(fig)
    # end

    display(fig)
    println("\r$(Parameters.oksymbol) Succeeded!                                                  ")

    return nothing
end

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
function Extrema(data, nbpoints = 30)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end
    if nbpoints > data.nbnodesLayer || nbpoints < 0
        println("$(Parameters.noksymbol) Incorrect number of visualization points")
        return
    end

    # initial values
    print("$(Parameters.hand) Memory caching...")
    flush(stdout)
    allvalues = Observable(Selafin.GetAllTime(data, 1, 1))
    println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
    values = allvalues[][1, :]
    lenmaxvalues = nbpoints - 1
    absvalues = abs.(values)
    sortvalues = sort(absvalues)
    permvalues = sortperm(absvalues)
    minmaxvalues = sortvalues[length(values)-lenmaxvalues:length(values)]
    minmaxpermvalues = permvalues[length(values)-lenmaxvalues:length(values)]
    x = data.x[1:data.nbnodesLayer]
    y = data.y[1:data.nbnodesLayer]
    
    
    # observables
    valp = Observable(minmaxvalues)
    xp = Observable(x[minmaxpermvalues])
    yp = Observable(y[minmaxpermvalues])
    varnumber = Observable(1)
    layernumber = Observable(1)
    timenumber = Observable(1)
    colorschoice = Observable(:viridis)
    valchoice = Observable("Largest")
    
    # figure
    print("$(Parameters.hand) Pending GPU-powered 2D plot... (this may take a while)")
    flush(stdout)
    fig = Figure(resolution = (1280, 1024))
    Axis(fig[1, 1], xlabel = "xcoordinates (m)", ylabel = "ycoordinates (m)")
    Colorbar(fig[1, 2], label = "Normalized values", colormap = colorschoice)
    scatter!(fig[1, 1], x, y, color = (:gray, 0.5), marker = '.', markersize = 20)
    scatter!(fig[1, 1], xp, yp, color = valp, marker = Parameters.circle, colormap = colorschoice)

    # slider (time step)
    time_slider = SliderGrid(fig[2, 1], (label = "Time step number", range = 1:1:data.nbsteps, startvalue = 1))
    on(time_slider.sliders[1].value) do timeval
        timenumber[] = timeval
        values = allvalues[][timeval, :]
        absvalues = abs.(values)
        sortvalues = sort(absvalues)
        permvalues = sortperm(absvalues)
        if valchoice.val == "Largest"
            minmaxvalues = sortvalues[length(values)-nbpoints+1:length(values)]
            minmaxpermvalues = permvalues[length(values)-nbpoints+1:length(values)]
        else
            minmaxvalues = sortvalues[1:nbpoints]
            minmaxpermvalues = permvalues[1:nbpoints]
        end
        valp[] = minmaxvalues
        xp[] = x[minmaxpermvalues]
        yp[] = y[minmaxpermvalues]
    end
    
    # menu (variable number)
    varchoice = Menu(fig, options = data.varnames, i_selected = 1)
    on(varchoice.selection) do selected_variable
        varnumber[] = findall(occursin.(selected_variable, data.varnames))[1]
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        allvalues[] = Selafin.GetAllTime(data, varnumber.val, layernumber.val)
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
        values = allvalues[][timenumber.val, :]
        absvalues = abs.(values)
        sortvalues = sort(absvalues)
        permvalues = sortperm(absvalues)
        if valchoice.val == "Largest"
            minmaxvalues = sortvalues[length(values)-nbpoints+1:length(values)]
            minmaxpermvalues = permvalues[length(values)-nbpoints+1:length(values)]
        else
            minmaxvalues = sortvalues[1:nbpoints]
            minmaxpermvalues = permvalues[1:nbpoints]
        end
        valp[] = minmaxvalues
        xp[] = x[minmaxpermvalues]
        yp[] = y[minmaxpermvalues]
    end
    
    # menu (layer number)
    layerchoice = Menu(fig, options = 1:data.nblayers, i_selected = 1)
    on(layerchoice.selection) do selected_layer
        layernumber[] = selected_layer
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        allvalues[] = Selafin.GetAllTime(data, varnumber.val, layernumber.val)
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
        values = allvalues[][timenumber.val, :]
        absvalues = abs.(values)
        sortvalues = sort(absvalues)
        permvalues = sortperm(absvalues)
        if valchoice.val == "Largest"
            minmaxvalues = sortvalues[length(values)-nbpoints+1:length(values)]
            minmaxpermvalues = permvalues[length(values)-nbpoints+1:length(values)]
        else
            minmaxvalues = sortvalues[1:nbpoints]
            minmaxpermvalues = permvalues[1:nbpoints]
        end
        valp[] = minmaxvalues
        xp[] = x[minmaxpermvalues]
        yp[] = y[minmaxpermvalues]
    end
    
    # menu (colorscheme)
    colorchoice = Menu(fig, options = Parameters.scientific, i_selected = 25)
    on(colorchoice.selection) do selected_color
        colorschoice[] = selected_color
    end


    # menu (min/max choice)
    extrchoice = Menu(fig, options = ["Largest", "Smallest"], i_selected = 1)
    on(extrchoice.selection) do selected_choice
        valchoice[] = selected_choice
        values = allvalues[][timenumber.val, :]
        absvalues = abs.(values)
        sortvalues = sort(absvalues)
        permvalues = sortperm(absvalues)
        if selected_choice == "Largest"
            minmaxvalues = sortvalues[length(values)-nbpoints+1:length(values)]
            minmaxpermvalues = permvalues[length(values)-nbpoints+1:length(values)]
        else
            minmaxvalues = sortvalues[1:nbpoints]
            minmaxpermvalues = permvalues[1:nbpoints]
        end
        valp[] = minmaxvalues
        xp[] = x[minmaxpermvalues]
        yp[] = y[minmaxpermvalues]
    end

  
    # button (save figure)
    savefig = Button(fig, label="Save Figure")

    # layout
    fig[3,1] = hgrid!(
        Label(fig, "Variable:"), varchoice,
        Label(fig, "Layer:"), layerchoice,
        Label(fig, "Values:"), extrchoice
    )
    
    fig[4,1] = hgrid!(Label(fig, "Colors:"), colorchoice,
        savefig
    )

    display(fig)
    println("\r$(Parameters.oksymbol) Succeeded!                                                  ")

    return nothing
end

# Plot2D.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
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
"""
    Plot2D(data)

    2D mesh plot of time-dependent Telemac results

    Use of the mesh() Makie function
    
    # Arguments
        - `data::Struct`: Selafin file information provided by the Read(filename) function
"""
function Plot2D(data)

    if typeof(data) != Data
        if data.verbose == true println("$(Parameters.noksymbol) Parameter is not a Data struct") end
        return
    end

    # observables
    if data.verbose == true
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
    end
    allvalues = Observable(Selafin.GetAllTime(data, 1, 1))
    if data.verbose == true println("\r$(Parameters.oksymbol) Memory caching...Done!                    ") end
    values = Observable(allvalues[][1, :])
    varnumber = Observable(1)
    layernumber = Observable(1)
    timenumber = Observable(1)
    colorschoice = Observable(:viridis)

    # figure
    if data.verbose == true
        print("$(Parameters.hand) Pending GPU-powered 2D plot... (this may take a while)")
        flush(stdout)
    end
    GLMakie.closeall()
    fig = Figure(size = (1280, 1024))
    Axis(fig[1, 1], xlabel = "x-coordinates (m)", ylabel = "y-coordinates (m)")
    Colorbar(fig[1, 2], label = "Normalized values", colormap = colorschoice)
    mesh!([data.x[1:data.nbnodesLayer] data.y[1:data.nbnodesLayer]], data.ikle[1:data.nbtrianglesLayer, 1:3], color=values, colormap=colorschoice, shading=NoShading)

    # slider (time step)
    time_slider = SliderGrid(fig[2, 1], (label = "Time step number", range = 1:1:data.nbsteps, startvalue = 1))
    on(time_slider.sliders[1].value) do timeval
        values[] = allvalues[][timeval, :]
        timenumber[] = timeval
    end

    # menu (variable number)
    varchoice = Menu(fig, options = data.varnames, i_selected = 1)
    on(varchoice.selection) do selected_variable
        varnumber[] = findall(occursin.(selected_variable, data.varnames))[1]
        if data.verbose == true
            print("$(Parameters.hand) Memory caching...")
            flush(stdout)
        end
        allvalues[] = Selafin.GetAllTime(data, varnumber.val, layernumber.val)
        if data.verbose == true println("\r$(Parameters.oksymbol) Memory caching...Done!                    ") end
        values[] = allvalues[][timenumber.val, :]
    end

    # menu (layer number)
    layerchoice = Menu(fig, options = 1:data.nblayers, i_selected = 1)
    on(layerchoice.selection) do selected_layer
        layernumber[] = selected_layer
        if data.verbose == true
            print("$(Parameters.hand) Memory caching...")
            flush(stdout)
        end
        allvalues[] = Selafin.GetAllTime(data, varnumber.val, layernumber.val)
        if data.verbose == true println("\r$(Parameters.oksymbol) Memory caching...Done!                    ") end
        values[] = allvalues[][timenumber.val, :]
    end

    # menu (colorscheme)
    colorchoice = Menu(fig, options = Parameters.scientific, i_selected = 25)
    on(colorchoice.selection) do selected_color
        colorschoice[] = selected_color
    end

    # button (save figure)
    savefig = Button(fig, label="Save Figure")

    # button (save animation)
    savemp4 = Button(fig, label="Save Animation")

    # layout
    fig[3,1] = hgrid!(
        Label(fig, "Variable:"), varchoice,
        Label(fig, "Layer:"), layerchoice,
        Label(fig, "Colors:"), colorchoice,
        savefig,
        savemp4
    )

    # save figure on button click
    on(savefig.clicks) do clicks
        newfig = Figure(size = (1280, 1024))
        strtime = convertSeconds((timenumber.val - 1) * data.timestep)
        Axis(newfig[1, 1], title=data.varnames[varnumber.val]*" TIME($(strtime)) "*" NB_LAYER($(layernumber.val)) ", xlabel = "x-coordinates (m)", ylabel = "y-coordinates (m)")
        mesh!([data.x[1:data.nbnodesLayer] data.y[1:data.nbnodesLayer]], data.ikle[1:data.nbtrianglesLayer, 1:3], color=values, colormap=colorschoice, shading=NoShading)
        maxvar = maximum(values.val)
        minvar = minimum(values.val)
        if minvar == maxvar
            maxvar = minvar + Parameters.eps
        end
        Colorbar(newfig[1, 2], limits = (minvar, maxvar), colormap = colorschoice)
        figname = "Selafin Plot2D "*replace(replace(string(Dates.now()), 'T' => " at "), ':' => '.')*".png"
        save(figname, newfig, px_per_unit = 2)
        if data.verbose == true println("$(Parameters.oksymbol) Figure saved") end
        # display(fig)
    end

    # save animation on button click
    on(savemp4.clicks) do clicks
        time = Observable(0.0)
        timestamps = 1:data.nbsteps
        newfig = Figure(size = (1280, 1024))
        strtime = convertSeconds((time.val - 1) * data.timestep)
        Axis(newfig[1, 1], title=@lift(data.varnames[varnumber.val]*" TIME($(convertSeconds(($time - 1) * data.timestep))) "*" NB_LAYER($(layernumber.val)) "), xlabel = "x-coordinates (m)", ylabel = "y-coordinates (m)")
        Colorbar(newfig[1, 2], label = "Normalized values", colormap = colorschoice)
        mesh!([data.x[1:data.nbnodesLayer] data.y[1:data.nbnodesLayer]], data.ikle[1:data.nbtrianglesLayer, 1:3], color=values, colormap=colorschoice, shading=NoShading)
        record(newfig, "animation.mp4", timestamps; framerate = 24) do t
            time[] = t
            values[] = Selafin.Get(data, varnumber.val, t, layernumber.val)
        end
        if data.verbose == true println("$(Parameters.oksymbol) Animation saved to .mp4 file") end
        # display(fig)
    end

    display(fig)
    if data.verbose == true println("\r$(Parameters.oksymbol) Succeeded!                                                  ") end

    return nothing
end

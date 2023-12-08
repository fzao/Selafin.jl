# PlotField.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# 2D interactive plot of velocity field with GLMakie
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
    PlotField(data)

    2D quiver plot of the velocity field

    Use of the arrows() Makie function
    
    # Arguments
        - `data::Struct`: Selafin file information provided by the Read(filename) function
"""
function PlotField(data)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end
    numu = 0
    for i in 1:data.nbvars
        if data.varnames[i][1:10] == "VELOCITY U" || data.varnames[i][1:9] == "VITESSE U"
            numu = i
            break
        end
    end
    numv = 0
    for i in 1:data.nbvars
        if data.varnames[i][1:10] == "VELOCITY V" || data.varnames[i][1:9] == "VITESSE V"
            numv = i
            break
        end
    end
    if numu == 0 || numv == 0
        println("$(Parameters.noksymbol) No velocity field found in data")
        return
    else
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        utime = Observable(Selafin.GetAllTime(data, numu, 1))
        vtime = Observable(Selafin.GetAllTime(data, numv, 1))
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
    end

    # initialization
    x = data.x[1:data.nbnodesLayer]
    y = data.y[1:data.nbnodesLayer]
    max_length_arrow = 1000

    # observables
    u = Observable(utime[][1, :])
    v = Observable(vtime[][1, :])
    magnitude = Observable(vec(sqrt.(u.val .^ 2 .+ v.val .^ 2)))
    layernumber = Observable(1)
    timenumber = Observable(1)
    colorschoice = Observable(:viridis)
    lenarrow = Observable(500)

    # figure
    print("$(Parameters.hand) Pending GPU-powered 2D plot... (this may take a while)")
    flush(stdout)
    GLMakie.closeall()
    fig = Figure(size = (1280, 1024))
    Axis(fig[1, 1], xlabel = "x-coordinates (m)", ylabel = "y-coordinates (m)")
    Colorbar(fig[1, 2], label = "Normalized values", colormap = colorschoice)
    arrows!(x, y, u, v, arrowsize = 10, lengthscale = lenarrow, arrowcolor = magnitude, linecolor = magnitude, colormap = colorschoice)

    # slider (time step)
    time_slider = SliderGrid(fig[2, 1], (label = "Time step number", range = 1:1:data.nbsteps, startvalue = 1))
    on(time_slider.sliders[1].value) do timeval
        u[] = utime[][timeval, :]
        v[] = vtime[][timeval, :]
        magnitude[] = vec(sqrt.(u.val .^ 2 .+ v.val .^ 2))
        timenumber[] = timeval
    end

    # menu (layer number)
    layerchoice = Menu(fig, options = 1:data.nblayers, i_selected = 1)
    on(layerchoice.selection) do selected_layer
        layernumber[] = selected_layer
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        utime[] = Selafin.GetAllTime(data, numu, layernumber.val)
        vtime[] = Selafin.GetAllTime(data, numv, layernumber.val)
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
        u[] = utime[][timenumber.val, :]
        v[] = vtime[][timenumber.val, :]
        magnitude[] = vec(sqrt.(u.val .^ 2 .+ v.val .^ 2))
    end

    # slider (length arrow)
    arrow_slider = SliderGrid(fig, (range = 0:0.05:1, startvalue = lenarrow.val / max_length_arrow))
    on(arrow_slider.sliders[1].value) do arrow
        lenarrow[] = arrow * max_length_arrow
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
        Label(fig, "Layer:"), layerchoice,
        Label(fig, "Arrow length:"), arrow_slider,
        Label(fig, "Colors:"), colorchoice,
        savefig
    )

    # save figure on button click
    on(savefig.clicks) do clicks
        newfig = Figure(size = (1280, 1024))
        strtime = convertSeconds((timenumber.val - 1) * data.timestep)
        Axis(newfig[1, 1], title="Velocity Field (m/s)    TIME($(strtime)) "*" NB_LAYER($(layernumber.val)) ", xlabel = "x-coordinates (m)", ylabel = "y-coordinates (m)")
        arrows!(x, y, u, v, arrowsize = 10, lengthscale = lenarrow.val, arrowcolor = magnitude, linecolor = magnitude, colormap = colorschoice)
        maxvar = maximum(magnitude.val)
        minvar = minimum(magnitude.val)
        if minvar == maxvar
            maxvar = minvar + Parameters.eps
        end
        Colorbar(newfig[1, 2], limits = (minvar, maxvar), colormap = colorschoice)
        figname = "Selafin PlotField "*replace(replace(string(Dates.now()), 'T' => " at "), ':' => '.')*".png"
        save(figname, newfig, px_per_unit = 2)
        println("$(Parameters.oksymbol) Figure saved")
        # display(fig)
    end

    display(fig)
    println("\r$(Parameters.oksymbol) Succeeded!                                                  ")

    return nothing
end

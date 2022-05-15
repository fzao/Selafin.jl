# Animation.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# 2D interactive animation with GLMakie
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
function Anim(data)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end

    values = Observable(Selafin.Get(data,1,1,1));
    varnumber = Observable(1)
    layernumber = Observable(1)
    timenumber = Observable(1)
    colorschoice = Observable(:viridis)
    scientific = [:acton, :bamako, :batlow, :berlin, :bilbao, :broc, :buda, :cork, :davos, :devon, :grayC, :hawaii, :imola, :lajolla, :lapaz, :lisbon, :nuuk, :oleron, :oslo, :roma, :tofino, :tokyo, :turku, :vik, :viridis]

    fig = Figure(resolution = (1440, 1080))
    ax = Axis(fig[1, 1], xlabel = "x-coordinates (m)", ylabel = "y-coordinates (m)")

    function updateTitle()
        strtime = convertSeconds((timenumber.val - 1) * data.timestep)
        ax.title = data.varnames[varnumber.val]*" TIME($(strtime)) "*" NB_LAYER($(layernumber.val)) "
    end
    
    mesh!([data.x[1:data.nbnodesLayer] data.y[1:data.nbnodesLayer]], data.ikle[1:data.nbtrianglesLayer, 1:3], color=values, colormap=colorschoice, shading=false)
    updateTitle()
    
    time_slider = SliderGrid(fig[2, 1], (label = "Time step number", range = 1:1:data.nbsteps, startvalue = 1))
    on(time_slider.sliders[1].value) do timeval
        values[] = Selafin.Get(data, varnumber.val, timeval, layernumber.val)
        timenumber[] = timeval
        updateTitle()
    end
    
    varchoice = Menu(fig, options = data.varnames, prompt = "Variable name")
    on(varchoice.selection) do selected_variable
        varnumber[] = findall(occursin.(selected_variable, data.varnames))[1]
        values[] = Selafin.Get(data,varnumber.val, timenumber.val, 1)
        updateTitle()
    end
    
    layerchoice = Menu(fig, options = 1:data.nblayers, prompt = "Layer number")
    on(layerchoice.selection) do selected_layer
        layernumber[] = selected_layer
        values[] = Selafin.Get(data,varnumber.val, timenumber.val, layernumber.val)
        updateTitle()
    end
    
    colorchoice = Menu(fig, options = scientific, prompt = "Colors choice")
    on(colorchoice.selection) do selected_color
        colorschoice[] = selected_color
    end
    
    fig[3,1] = hgrid!(
        Label(fig, "Variable:"), varchoice,
        Label(fig, "Layer:"), layerchoice,
        Label(fig, "Colors:"), colorchoice
    )    

    display(fig)

    return nothing
end

# Histogram.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# Interactive histograms of variables with GLMakie
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
function Histogram(data)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end

    # observables
    values = Observable(Selafin.Get(data,1,1,1));
    varnumber = Observable(1)
    layernumber = Observable(1)
    timenumber = Observable(1)

    # search for the axis limits of all histograms
    nbins = 50  # optimal?
    xybounds = zeros(Float64, data.nbvars, data.nblayers, 3)
    xybounds[:, :, 1] .= Inf  # min(min(x(t)))
    xybounds[:, :, 2] .= -Inf # max(max(x(t)))
    xybounds[:, :, 3] .= 0    # max(max(y(t)))
    variables = Array{data.typefloat, 1}(undef, data.nbnodesLayer * data.nblayers)
    timevalue =  Array{Float32, 1}(undef, data.nbsteps)
    fid = open(data.filename, "r")
    seek(fid, data.markposition)
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
            val = reshape(variables, data.nbnodesLayer, data.nblayers)
            for p in 1:data.nblayers
                isovalues = val[:, p]
                minvar = minimum(isovalues)
                maxvar = maximum(isovalues)
                if !isapprox(minvar, maxvar)
                    if minvar < xybounds[v, p, 1]
                        xybounds[v, p, 1] = minvar
                    end
                    if maxvar > xybounds[v, p, 2]
                        xybounds[v, p, 2] = maxvar
                    end
                    ymax = maximum(fit(StatsBase.Histogram, isovalues, nbins=nbins).weights)
                    if ymax > xybounds[v, p, 3]
                        xybounds[v, p, 3] = ymax
                    end
                end
            end
        end
    end
    close(fid)

    # figure
    print("$(Parameters.hand) Pending GPU-powered histogram... (this may take a while)")
    flush(stdout)
    fig = Figure(resolution = (1280, 1024))
    ax = Axis(fig[1, 1], xlabel = "Values", ylabel = "Frequency")
    limits!(ax, xybounds[varnumber.val, layernumber.val, 1], xybounds[varnumber.val, layernumber.val, 2], 0, xybounds[varnumber.val, layernumber.val, 3])
    hist!(ax, values, bins = nbins, color = :gray, strokewidth = 1, strokecolor = :black)

    # slider (time step)
    time_slider = SliderGrid(fig[2, 1], (label = "Time step number", range = 1:1:data.nbsteps, startvalue = 1))
    on(time_slider.sliders[1].value) do timeval
        values[] = Selafin.Get(data, varnumber.val, timeval, layernumber.val)
        timenumber[] = timeval
    end

    # menu (variable number)
    varchoice = Menu(fig, options = data.varnames, i_selected = 1)
    on(varchoice.selection) do selected_variable
        varnumber[] = findall(occursin.(selected_variable, data.varnames))[1]
        values[] = Selafin.Get(data,varnumber.val, timenumber.val, 1)
        limits!(ax, xybounds[varnumber.val, layernumber.val, 1], xybounds[varnumber.val, layernumber.val, 2], 0, xybounds[varnumber.val, layernumber.val, 3])
    end

    # menu (layer number)
    layerchoice = Menu(fig, options = 1:data.nblayers, i_selected = 1)
    on(layerchoice.selection) do selected_layer
        layernumber[] = selected_layer
        values[] = Selafin.Get(data,varnumber.val, timenumber.val, layernumber.val)
        limits!(ax, xybounds[varnumber.val, layernumber.val, 1], xybounds[varnumber.val, layernumber.val, 2], 0, xybounds[varnumber.val, layernumber.val, 3])
    end

    # button (save figure)
    savefig = Button(fig, label="Save Figure")

    # layout
    fig[3,1] = hgrid!(
        Label(fig, "Variable:"), varchoice,
        Label(fig, "Layer:"), layerchoice,
        savefig
    )

    # save figure on button click
    # on(savefig.clicks) do clicks
    #     newfig = Figure(resolution = (1280, 1024))
    #     strtime = convertSeconds((timenumber.val - 1) * data.timestep)
    #     Axis(newfig[1, 1], title=data.varnames[varnumber.val]*" TIME($(strtime)) "*" NB_LAYER($(layernumber.val)) ", xlabel = "x-coordinates (m)", ylabel = "y-coordinates (m)")
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
    println("\r$(Parameters.oksymbol) Succeeded!                                             ")

    return nothing
end

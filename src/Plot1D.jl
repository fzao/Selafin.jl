# Plot1D.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# 1D interactive plot with GLMakie
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
    Plot1D(data)

    Plotting the results of a time-dependent Telemac variable

    Use of the lines() Makie function
    
    # Arguments
        - `data::Struct`: Selafin file information provided by the Read(filename) function
"""
function Plot1D(data)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end

    # observables
    print("$(Parameters.hand) Memory caching...")
    flush(stdout)
    println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
    varnumber = Observable(1)
    layernumber = Observable(1)
    nodenum = Observable(1)
    allvalues = Observable(Selafin.GetAllTime(data, 1, 1))
    values = Observable(allvalues[][:, nodenum[]])
    
    # figure
    print("$(Parameters.hand) Pending GPU-powered 1D plot... (this may take a while)")
    flush(stdout)
    GLMakie.closeall()
    xs = 1:1:data.nbsteps
    fig = Figure(size = (1280, 1024))
    ax = Axis(fig[1, 1], xlabel = "Time steps", ylabel = "Values")
    lines!(fig[1, 1], xs, values)
    
    # menu (node number)
    tb = Textbox(fig, placeholder = "Node number", validator = Int32)
    on(tb.stored_string) do s
        nodenum[] = parse(Int32, s)
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        allvalues[] = Selafin.GetAllTime(data, varnumber.val, layernumber.val)
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
        values[] = allvalues[][:, nodenum[]]
        ylims!(ax, minimum(values.val), maximum(values.val))
    end

    # menu (variable number)
    varchoice = Menu(fig, options = data.varnames, i_selected = 1)
    on(varchoice.selection) do selected_variable
        varnumber[] = findall(occursin.(selected_variable, data.varnames))[1]
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        allvalues[] = Selafin.GetAllTime(data, varnumber.val, layernumber.val)
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
        values[] = allvalues[][:, nodenum[]]
        ylims!(ax, minimum(values.val), maximum(values.val))
    end

    # menu (layer number)
    layerchoice = Menu(fig, options = 1:data.nblayers, i_selected = 1)
    on(layerchoice.selection) do selected_layer
        layernumber[] = selected_layer
        print("$(Parameters.hand) Memory caching...")
        flush(stdout)
        allvalues[] = Selafin.GetAllTime(data, varnumber.val, layernumber.val)
        println("\r$(Parameters.oksymbol) Memory caching...Done!                    ")
        values[] = allvalues[][:, nodenum[]]
        ylims!(ax, minimum(values.val), maximum(values.val))
    end

    # button (save figure)
    savefig = Button(fig, label="Save Figure")

    # layout
    fig[2,1] = hgrid!(
        Label(fig, "Variable:"), varchoice,
        Label(fig, "Layer:"), layerchoice,
        Label(fig, "Node:"), tb,
        savefig
    )

    # save figure on button click
    on(savefig.clicks) do clicks
        newfig = Figure(size = (1280, 1024))
        Axis(fig[1, 1], xlabel = "Time steps", ylabel = "Values")
        lines!(fig[1, 1], xs, values)
        figname = "Selafin Plot1D "*replace(replace(string(Dates.now()), 'T' => " at "), ':' => '.')*".png"
        save(figname, newfig, px_per_unit = 2)
        println("$(Parameters.oksymbol) Figure saved")
        # display(fig)
    end

    display(fig)
    println("\r$(Parameters.oksymbol) Succeeded!                                                  ")

    return nothing
end
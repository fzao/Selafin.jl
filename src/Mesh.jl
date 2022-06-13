# Mesh.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# Compute the 2D mesh quality of the Telemac case
# Optionally displays (figopt parameter) and prints out (figname parameter) the results
# Return the array of the mesh quality
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
    Quality(data, [figopt, figname, quaval])

    Information on the 2D triangular mesh quality
    Gives a histogram of a quality measure (aspect ratio) of all the elements
    Highligths the worst triangles (i.e. under the given threshold as parameter)
    
    # Arguments
        - `data::Struct`: Selafin file information provided by the Read(filename) function
        - `figopt::Bool`: Optional parameter for plotting (default: false)
        - `figname::String`: Optional parameter for the file name of the plot saved on drive (default: nothing)
        - `quaval::Float32`: Optional parameter for the detection threshold of bad triangles based on an aspect ratio (default: 0.5)
"""
function Quality(data, figopt=false, figname=nothing, quaval=Parameters.minqualval)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) The first parameter is not a Data struct")
        return
    end

    area = 0.
    triarea = Array{data.typefloat, 1}(undef, data.nbtrianglesLayer)
    triquality = Array{data.typefloat, 1}(undef, data.nbtrianglesLayer)
    cte = 4 * sqrt(3)
    for t in 1:data.nbtrianglesLayer
        pt1 = data.ikle[t, 1]
        pt2 = data.ikle[t, 2]
        pt3 = data.ikle[t, 3]
        triarea[t] = 0.5 * abs(((data.x[pt2] - data.x[pt1]) * (data.y[pt3] - data.y[pt1]) - (data.x[pt3] - data.x[pt1]) * (data.y[pt2] - data.y[pt1])))
        area += triarea[t]
        divlen = Distance.euclidean2(data.x[pt1], data.y[pt1], data.x[pt2], data.y[pt2]) +
                 Distance.euclidean2(data.x[pt1], data.y[pt1], data.x[pt3], data.y[pt3]) +
                 Distance.euclidean2(data.x[pt2], data.y[pt2], data.x[pt3], data.y[pt3])
        triquality[t] = divlen > Parameters.eps ? cte * triarea[t] / divlen : 0.
    end
    badqualnumber = count(<(quaval), triquality)
    badqualind = findall(triquality .< quaval)
    badqualval = triquality[badqualind]
    minqual = round(minimum(triquality), digits = 2)
    meanqual = round(mean(triquality), digits = 2)
    maxqual = round(maximum(triquality), digits = 2)
    histo = fit(StatsBase.Histogram, triquality, 0:0.1:1.0)
    histqual = histo.weights
    println("$(Parameters.oksymbol) Mesh quality (Min: $minqual, Mean: $meanqual, Max: $maxqual)")
    println("\t$(Parameters.smallsquare) Triangles")
    for i = 1:10
        a = round((i - 1) * 0.1, digits = 1)
        b = round(i * 0.1, digits = 1)
        println("\t$a...$b: $(histqual[i])")
    end

    if figopt
        area = round(area * 0.5e-6, digits = 2)
        strbadqualnumber = insertcommas(badqualnumber)

        # Mesh: get all segments
        ikle2 = sort(data.ikle, dims = 2)
        segments = Array{Tuple{Int32, Int32}}(undef, data.nbtrianglesLayer * 3, 1)
        k = 1
        for t in 1:data.nbtrianglesLayer
            segments[k] = (ikle2[t, 1], ikle2[t, 2])
            k += 1
            segments[k] = (ikle2[t, 1], ikle2[t, 3])
            k += 1
            segments[k] = (ikle2[t, 2], ikle2[t, 3])
            k += 1
        end
        segmentId = Array{String, 1}(undef, size(segments)[1])
        for i in 1:size(segments)[1]
            a = segments[i][1]
            b = segments[i][2]
            if a < b
                segmentId[i] = string(string(a), ' ', string(b))
            else
                segmentId[i] = string(string(b), ' ', string(a))
            end
        end
        segsave = segments
        segmentUniqueId = unique(i -> segmentId[i], 1:length(segmentId))
        segments = segments[segmentUniqueId]
        segmentsize = size(segments)[1]
        ptxall = Array{Float32, 1}(undef, 3 * segmentsize)
        ptyall = Array{Float32, 1}(undef, 3 * segmentsize)
        k = 1
        for i in 1:segmentsize
            pt1 = segments[i][1]
            pt2 = segments[i][2]
            ptxall[k] = data.x[pt1]
            ptyall[k] = data.y[pt1]
            k += 1
            ptxall[k] = data.x[pt2]
            ptyall[k] = data.y[pt2]
            k += 1
            ptxall[k] = NaN
            ptyall[k] = NaN
            k += 1
        end

        # Mesh: get boundary segments and coordinates
        dicCount = countmap(segsave)
        segmentBoundary = [segsave[i] for i in 1:size(segsave)[1] if dicCount[segsave[i]]==1]

        segmentsize = size(segmentBoundary)[1]
        ptxbnd = Array{Float32, 1}(undef, 3 * segmentsize)
        ptybnd = Array{Float32, 1}(undef, 3 * segmentsize)
        k = 1
        for i in 1:segmentsize
            pt1 = segmentBoundary[i][1]
            pt2 = segmentBoundary[i][2]
            ptxbnd[k] = data.x[pt1]
            ptybnd[k] = data.y[pt1]
            k += 1
            ptxbnd[k] = data.x[pt2]
            ptybnd[k] = data.y[pt2]
            k += 1
            ptxbnd[k] = NaN
            ptybnd[k] = NaN
            k += 1
        end

        # Mesh: bad triangle segments
        if badqualnumber > 0
            ptxbad = Array{Float32, 1}(undef, 9 * badqualnumber)
            ptybad = Array{Float32, 1}(undef, 9 * badqualnumber)
            k = 1
            for i in 1:badqualnumber
                pt1 = data.ikle[badqualind[i], 1]
                pt2 = data.ikle[badqualind[i], 2]
                pt3 = data.ikle[badqualind[i], 3]
                ptxbad[k] = data.x[pt1]
                ptybad[k] = data.y[pt1]
                k += 1
                ptxbad[k] = data.x[pt2]
                ptybad[k] = data.y[pt2]
                k += 1
                ptxbad[k] = NaN
                ptybad[k] = NaN
                k += 1
                ptxbad[k] = data.x[pt2]
                ptybad[k] = data.y[pt2]
                k += 1
                ptxbad[k] = data.x[pt3]
                ptybad[k] = data.y[pt3]
                k += 1
                ptxbad[k] = NaN
                ptybad[k] = NaN
                k += 1
                ptxbad[k] = data.x[pt1]
                ptybad[k] = data.y[pt1]
                k += 1
                ptxbad[k] = data.x[pt3]
                ptybad[k] = data.y[pt3]
                k += 1
                ptxbad[k] = NaN
                ptybad[k] = NaN
                k += 1
            end
        end

        # Mesh: get the perimeter value
        perimeter = 0.
        for s in 1:segmentsize
            pt1 = segmentBoundary[s][1]
            pt2 = segmentBoundary[s][2]
            perimeter += Distance.euclidean(data.x[pt1], data.y[pt1], data.x[pt2], data.y[pt2])
        end
        perimeter = round(perimeter * 1e-3, digits = 1)
        println("$(Parameters.oksymbol) Study area surface: $area km$(Parameters.superscripttwo) and perimeter: $perimeter km")

        # plot
        print("$(Parameters.hand) Pending GPU-powered graphs... (this may take a while)")
        flush(stdout)
        fig = Figure(resolution = (1280, 1024))
        ax1, l1 = lines(fig[1, 1], ptxall, ptyall)
        ax2, l2 = lines(fig[1, 2], ptxbnd, ptybnd)
        ax1.title = "Mesh ($(data.nbtrianglesLayer) triangles)"
        ax2.title = "Boundary ($perimeter km) - $strbadqualnumber bad triangle(s)"
        ax1.xlabel = "x-coordinates (m)"
        ax2.xlabel = "x-coordinates (m)"
        ax1.ylabel = "y-coordinates (m)"
        ax2.ylabel = "y-coordinates (m)"
        if badqualnumber > 0
            lines!(fig[1, 2], ptxbad, ptybad, color = :red)
            ax3, l3 = hist(fig[2, 1], triquality)
            if badqualnumber > 1
                ax4, l4 = hist(fig[2, 2], badqualval, color = :red)
            else
                ax4, l4 = barplot(fig[2, 2], badqualval, [1], color = :red, width = 0.01)
            end
            ax4.title = "Bad triangle(s): $strbadqualnumber"
            ax4.xlabel = "Mesh quality"
            ax4.ylabel = "Frequency"
        else
            ax3, l3 = hist(fig[2, 1:2], triquality)
        end
        ax3.title = "Min: $minqual, Mean: $meanqual, Max:$maxqual"
        ax3.xlabel = "Mesh quality"
        ax3.ylabel = "Frequency"

        if !isnothing(figname)
            save(figname, fig, px_per_unit = 2)
        end
        display(fig)
        println("\r$(Parameters.oksymbol) Succeeded!                                                  ")
    end

    return triquality

end

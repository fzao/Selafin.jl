using GLMakie
using Dates
using BenchmarkTools
include("./Distance.jl")
include("./Utils.jl")
include("./Parameters.jl")
include("./Model.jl")
include("./Read.jl")
using .Distance
using .Utils
using .Parameters
using .Model


# open the Selafin file
filename = "malpasset.slf"
results = Read(filename)
#filename = "mersey.slf"
#filename = "Alderney_sea_level.slf"
#filename = "Alderney.slf"
#filename = "girxl2d_result.slf"
# filename = "a9.slf"

# Mesh: domain description and quality
area = 0.
triarea = Array{results.typefloat, 1}(undef, results.nbtriangles)
triquality = Array{results.typefloat, 1}(undef, results.nbtriangles)
cte = 4 * sqrt(3)
for t in 1:results.nbtriangles
    pt1 = results.ikle[t, 1]
    pt2 = results.ikle[t, 2]
    pt3 = results.ikle[t, 3]
    triarea[t] = 0.5 * abs(((results.x[pt2] - results.x[pt1]) * (results.y[pt3] - results.y[pt1]) - (results.x[pt3] - results.x[pt1]) * (results.y[pt2] - results.y[pt1])))
    global area += triarea[t]
    divlen = Distance.euclidean2(results.x[pt1], results.y[pt1], results.x[pt2], results.y[pt2]) +
             Distance.euclidean2(results.x[pt1], results.y[pt1], results.x[pt3], results.y[pt3]) +
             Distance.euclidean2(results.x[pt2], results.y[pt2], results.x[pt3], results.y[pt3])
    triquality[t] = divlen > Parameters.eps ? cte * triarea[t] / divlen : 0.
end
badqualnumber = count(<(Parameters.minqualval), triquality)
badqualind = findall(triquality .< Parameters.minqualval)
badqualval = triquality[badqualind]
minqual = round(minimum(triquality), digits = 2)
meanqual = round(mean(triquality), digits = 2)
maxqual = round(maximum(triquality), digits = 2)
#= sortqualval = [badqualval badqualind]
sortqualval = sortslices(sortqualval, dims=1)
badqualval = sortqualval[:, 1]
badqualind = round.(Int, sortqualval[:, 2]) =#
area = round(area * 0.5e-6, digits = 2)

strbadqualnumber = insertcommas(badqualnumber)

# Mesh: get all segments
ikle2 = sort(results.ikle, dims = 2)
segments = Array{Tuple{Int32, Int32}}(undef, results.nbtriangles * 3, 1)
k = 1
for t in 1:results.nbtriangles
    segments[k] = (ikle2[t, 1], ikle2[t, 2])
    global k += 1
    segments[k] = (ikle2[t, 1], ikle2[t, 3])
    global k += 1
    segments[k] = (ikle2[t, 2], ikle2[t, 3])
    global k += 1
end
segsave = segments
segments = unique(segments, dims=1)
segmentsize = size(segments)[1]
ptxall = Array{Float32, 1}(undef, 3 * segmentsize)
ptyall = Array{Float32, 1}(undef, 3 * segmentsize)
k = 1
for i in 1:segmentsize
    pt1 = segments[i][1]
    pt2 = segments[i][2]
    ptxall[k] = results.x[pt1]
    ptyall[k] = results.y[pt1]
    global k += 1
    ptxall[k] = results.x[pt2]
    ptyall[k] = results.y[pt2]
    global k += 1
    ptxall[k] = NaN
    ptyall[k] = NaN
    global k += 1
end

# Mesh: get boundary segments
segcount = [(i, count(==(i), segsave)) for i in segsave]
segunique = [segcount[i][1] for i in 1:size(segcount)[1] if segcount[i][2]==1]
segmentsize = size(segunique)[1]
ptxbnd = Array{Float32, 1}(undef, 3 * segmentsize)
ptybnd = Array{Float32, 1}(undef, 3 * segmentsize)
k = 1
for i in 1:segmentsize
    pt1 = segunique[i][1]
    pt2 = segunique[i][2]
    ptxbnd[k] = results.x[pt1]
    ptybnd[k] = results.y[pt1]
    global k += 1
    ptxbnd[k] = results.x[pt2]
    ptybnd[k] = results.y[pt2]
    global k += 1
    ptxbnd[k] = NaN
    ptybnd[k] = NaN
    global k += 1
end

# Mesh: bad triangle segments
if badqualnumber > 0
    ptxbad = Array{Float32, 1}(undef, 9 * badqualnumber)
    ptybad = Array{Float32, 1}(undef, 9 * badqualnumber)
    k = 1
    for i in 1:badqualnumber
        pt1 = results.ikle[badqualind[i], 1]
        pt2 = results.ikle[badqualind[i], 2]
        pt3 = results.ikle[badqualind[i], 3]
        ptxbad[k] = results.x[pt1]
        ptybad[k] = results.y[pt1]
        global k += 1
        ptxbad[k] = results.x[pt2]
        ptybad[k] = results.y[pt2]
        global k += 1
        ptxbad[k] = NaN
        ptybad[k] = NaN
        global k += 1
        ptxbad[k] = results.x[pt2]
        ptybad[k] = results.y[pt2]
        global k += 1
        ptxbad[k] = results.x[pt3]
        ptybad[k] = results.y[pt3]
        global k += 1
        ptxbad[k] = NaN
        ptybad[k] = NaN
        global k += 1
        ptxbad[k] = results.x[pt1]
        ptybad[k] = results.y[pt1]
        global k += 1
        ptxbad[k] = results.x[pt3]
        ptybad[k] = results.y[pt3]
        global k += 1
        ptxbad[k] = NaN
        ptybad[k] = NaN
        global k += 1
    end
end

# Mesh: get the perimeter value
perimeter = 0.
for s in 1:segmentsize
    pt1 = segunique[s][1]
    pt2 = segunique[s][2]
    global perimeter += Distance.euclidean(results.x[pt1], results.y[pt1], results.x[pt2], results.y[pt2])
end
perimeter = round(perimeter * 1e-3, digits = 1)
println("$oksymbol Study area surface: $area km$(Parameters.superscripttwo) and perimeter: $perimeter km")

# plot
fig = Figure()
ax1, l1 = lines(fig[1, 1], ptxall, ptyall)
ax2, l2 = lines(fig[1, 2], ptxbnd, ptybnd)
ax1.title = "Mesh ($(results.nbtriangles) triangles)"
ax2.title = "Boundary ($perimeter km) - $strbadqualnumber bad triangles"
ax1.xlabel = "x-coordinates (m)"
ax2.xlabel = "x-coordinates (m)"
ax1.ylabel = "y-coordinates (m)"
ax2.ylabel = "y-coordinates (m)"
if badqualnumber > 0
    minval = minimum(badqualval)
    maxval = maximum(badqualval)
    lines!(fig[1, 2], ptxbad, ptybad, color = :red)
    ax3, l3 = hist(fig[2, 1], triquality)
    ax4, l4 = hist(fig[2, 2], badqualval, color = :red)
    ax4.title = "Bad triangles: $strbadqualnumber"
    ax4.xlabel = "Mesh quality"
    ax4.ylabel = "Frequency"
else
    ax3, l3 = hist(fig[2, 1:2], triquality)
end
ax3.title = "Min: $minqual, Mean: $meanqual, Max:$maxqual"
ax3.xlabel = "Mesh quality"
ax3.ylabel = "Frequency"

display(fig)


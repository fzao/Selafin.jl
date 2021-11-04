using GLMakie
using Dates
using BenchmarkTools
include("./Distance.jl")
include("./Utils.jl")
include("./Parameters.jl")
include("./Model.jl")
using .Distance
using .Utils
using .Parameters
using .Model


# open the Selafin file
sel_filename = "malpasset.slf"
#sel_filename = "mersey.slf"
#sel_filename = "Alderney_sea_level.slf"
#sel_filename = "Alderney.slf"
#sel_filename = "girxl2d_result.slf"
# sel_filename = "a9.slf"
bytesize = filesize(sel_filename)
if bytesize == 0
    error("$noksymbol The file $(sel_filename) does not exist")
end
if bytesize < filesizeunit["KB"]
    readbytesize = bytesize
    sizeunit = "Byte"
elseif bytesize < filesizeunit["MB"]
    readbytesize = bytesize / filesizeunit["KB"]
    sizeunit = "KB"
elseif bytesize < filesizeunit["GB"]
    readbytesize = bytesize / filesizeunit["MB"]
    sizeunit = "MB"
elseif bytesize < filesizeunit["TB"]
    readbytesize = bytesize / filesizeunit["GB"]
    sizeunit = "GB"
else
    readbytesize = bytesize / filesizeunit["TB"]
    sizeunit = "GB"
end
intreadbytesize = UInt16(round(readbytesize))
println("$oksymbol File $sel_filename of size: $intreadbytesize $sizeunit")
sel_fid = open(sel_filename, "r")

# read: Title
rec = ntoh(read(sel_fid, Int32))
sel_title = String(read(sel_fid, rec))
rec = ntoh(read(sel_fid, Int32))
sel_title = lstrip(rstrip(sel_title))
println("$oksymbol Name of the simulation: $sel_title")

# read: Number of variables (tri)
rec = ntoh(read(sel_fid, Int32))
sel_nbvars = ntoh(read(sel_fid, Int32))

# read: Number of variables (quad)
nbqvars = ntoh(read(sel_fid, Int32))
rec = ntoh(read(sel_fid, Int32))

# read: Variable names
sel_varnames = String[]
for i in 1:sel_nbvars
    localrec = ntoh(read(sel_fid, Int32))
    push!(sel_varnames, String(read(sel_fid, localrec)))
    localrec = ntoh(read(sel_fid, Int32))
end

# read: Forsegments (10 times 4 bytes is expected)
fmtid = ntoh(read(sel_fid, Int32))
if fmtid != 40
    println("$noksymbol Unknown forsegments for data recording")
    exit(fmtid)
end

# read: Integer parameters
sel_iparam = Int32[]
for i in 1:10
    push!(sel_iparam, ntoh(read(sel_fid, Int32)))
end
fmtid = ntoh(read(sel_fid, Int32))

# read: Date
idate = Int32[]
checkdate = 0
if sel_iparam[10] == 1
    rec = ntoh(read(sel_fid, Int32))
    for i in 1:6
        push!(idate, ntoh(read(sel_fid, Int32)))
    end
    rec = ntoh(read(sel_fid, Int32))
    checkdate = idate[1] * idate[2] * idate[3]
end
if checkdate == 0
    datehour = "Unknown"
else
    datehour = Dates.format(DateTime(idate[1], idate[2], idate[3], idate[4], idate[5], idate[6]), "yyyy-mm-dd HH:MM:SS")
end
println("$oksymbol Event start date and time: $datehour")

# read: Number of layers
nblayers = sel_iparam[7] != 0 ? sel_iparam[7] : 1
dimtelemac = nblayers == 1 ? "2D" : "3D"
println("$oksymbol Telemac $dimtelemac results with $sel_nbvars variables")
println("$oksymbol Variables are:")
for i = 1:sel_nbvars
    if i < 10
        spacing = "  - "
    else
        spacing = " - "
    end
    vname = lowercase(lstrip(rstrip(sel_varnames[i])))
    println("\t$i$spacing$vname")
end

# read: Mesh info (size)
rec = ntoh(read(sel_fid, Int32))
nbtriangles =  ntoh(read(sel_fid, Int32))
nbnodes =  ntoh(read(sel_fid, Int32))
nbptelem =  ntoh(read(sel_fid, Int32))
if nbptelem != 3
    println("$noksymbol Unknown type of mesh elements")
    exit(nbptelem)
end
unknown = ntoh(read(sel_fid, Int32))
rec = ntoh(read(sel_fid, Int32))
strnbtriangles = insertcommas(nbtriangles)
strnbnodes = insertcommas(nbnodes)
println("$oksymbol Unstructured mesh with $strnbtriangles triangles and $strnbnodes nodes")

# read: Mesh info (ikle connectivity)
rec = ntoh(read(sel_fid, Int32))
ikle = zeros(Int32, nbptelem, nbtriangles)
ikle = [ntoh(read(sel_fid, Int32)) for i in 1:nbptelem, j in 1:nbtriangles]
ikle = transpose(ikle)
rec = ntoh(read(sel_fid, Int32))

# read: Mesh info (ipobo boundary nodes)
rec = ntoh(read(sel_fid, Int32))
ipobo = zeros(Int32, nbnodes)
ipobo = [ntoh(read(sel_fid, Int32)) for i in 1:nbnodes]
rec = ntoh(read(sel_fid, Int32))

# read: Mesh info (xy coordinates)
rec = ntoh(read(sel_fid, Int32))
typefloat = nbnodes * 4 == rec ? Float32 : Float64
x = Array{typefloat, 1}(undef, nbnodes)
x = [ntoh(read(sel_fid, typefloat)) for i in 1:nbnodes]
rec = ntoh(read(sel_fid, Int32))
rec = ntoh(read(sel_fid, Int32))
y = Array{typefloat, 1}(undef, nbnodes)
y = [ntoh(read(sel_fid, Float32)) for i in 1:nbnodes]
rec = ntoh(read(sel_fid, Int32))

# read: Number of time steps
markposition = mark(sel_fid)
bytecount = bytesize - markposition
nbsteps = trunc(Int, bytecount / (sel_nbvars * nbnodes * sizeof(typefloat) + 8 * sel_nbvars +8))

# read: Variables
reset(sel_fid)
variables = Array{typefloat, 2}(undef, nbnodes, sel_nbvars)
timevalue =  Array{Float32, 1}(undef, nbsteps)
for t in 1:nbsteps
    recloc = ntoh(read(sel_fid, Int32))
    timevalue[t] = ntoh(read(sel_fid, Float32))
    recloc = ntoh(read(sel_fid, Int32))
    for v in 1:sel_nbvars
        recloc = ntoh(read(sel_fid, Int32))
        raw_data = zeros(UInt8, recloc)
        readbytes!(sel_fid, raw_data, recloc)
        variables[:,v] .= ntoh.(reinterpret(typefloat, raw_data))
        recloc = ntoh(read(sel_fid, Int32))
    end
end
if nbsteps > 1
    timesteps = timevalue[2] - timevalue[1]
    println("$oksymbol Number of time steps: $nbsteps with "*"$delta"*"t = $timesteps s")
else
    println("$oksymbol Number of time steps: $nbsteps")
end


# close the Selafin file
close(sel_fid)

# Mesh: domain description and quality
area = 0.
triarea = Array{typefloat, 1}(undef, nbtriangles)
triquality = Array{typefloat, 1}(undef, nbtriangles)
cte = 4 * sqrt(3)
for t in 1:nbtriangles
    pt1 = ikle[t, 1]
    pt2 = ikle[t, 2]
    pt3 = ikle[t, 3]
    triarea[t] = 0.5 * abs(((x[pt2] - x[pt1]) * (y[pt3] - y[pt1]) - (x[pt3] - x[pt1]) * (y[pt2] - y[pt1])))
    global area += triarea[t]
    divlen = Distance.euclidean2(x[pt1], y[pt1], x[pt2], y[pt2]) +
             Distance.euclidean2(x[pt1], y[pt1], x[pt3], y[pt3]) +
             Distance.euclidean2(x[pt2], y[pt2], x[pt3], y[pt3])
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
ikle2 = sort(ikle, dims = 2)
segments = Array{Tuple{Int32, Int32}}(undef, nbtriangles*3, 1)
k = 1
for t in 1:nbtriangles
    segments[k] = (ikle2[t,1],ikle2[t,2])
    global k += 1
    segments[k] = (ikle2[t,1],ikle2[t,3])
    global k += 1
    segments[k] = (ikle2[t,2],ikle2[t,3])
    global k += 1
end
segsave = segments
segments = unique(segments, dims=1)
segmentsize = size(segments)[1]
ptxall = Array{Float32, 1}(undef, 3*segmentsize)
ptyall = Array{Float32, 1}(undef, 3*segmentsize)
k = 1
for i in 1:segmentsize
    pt1 = segments[i][1]
    pt2 = segments[i][2]
    ptxall[k] = x[pt1]
    ptyall[k] = y[pt1]
    global k += 1
    ptxall[k] = x[pt2]
    ptyall[k] = y[pt2]
    global k += 1
    ptxall[k] = NaN
    ptyall[k] = NaN
    global k += 1
end

# Mesh: get boundary segments
segcount = [(i, count(==(i), segsave)) for i in segsave]
segunique = [segcount[i][1] for i in 1:size(segcount)[1] if segcount[i][2]==1]
segmentsize = size(segunique)[1]
ptxbnd = Array{Float32, 1}(undef, 3*segmentsize)
ptybnd = Array{Float32, 1}(undef, 3*segmentsize)
k = 1
for i in 1:segmentsize
    pt1 = segunique[i][1]
    pt2 = segunique[i][2]
    ptxbnd[k] = x[pt1]
    ptybnd[k] = y[pt1]
    global k += 1
    ptxbnd[k] = x[pt2]
    ptybnd[k] = y[pt2]
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
        pt1 = ikle[badqualind[i], 1]
        pt2 = ikle[badqualind[i], 2]
        pt3 = ikle[badqualind[i], 3]
        ptxbad[k] = x[pt1]
        ptybad[k] = y[pt1]
        global k += 1
        ptxbad[k] = x[pt2]
        ptybad[k] = y[pt2]
        global k += 1
        ptxbad[k] = NaN
        ptybad[k] = NaN
        global k += 1
        ptxbad[k] = x[pt2]
        ptybad[k] = y[pt2]
        global k += 1
        ptxbad[k] = x[pt3]
        ptybad[k] = y[pt3]
        global k += 1
        ptxbad[k] = NaN
        ptybad[k] = NaN
        global k += 1
        ptxbad[k] = x[pt1]
        ptybad[k] = y[pt1]
        global k += 1
        ptxbad[k] = x[pt3]
        ptybad[k] = y[pt3]
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
    global perimeter += Distance.euclidean(x[pt1], y[pt1], x[pt2], y[pt2])
end
perimeter = round(perimeter * 1e-3, digits = 1)
println("$oksymbol Study area surface: $area km$(Parameters.superscripttwo) and perimeter: $perimeter km")

# plot
fig = Figure()
ax1, l1 = lines(fig[1, 1], ptxall, ptyall)
ax2, l2 = lines(fig[1, 2], ptxbnd, ptybnd)
ax1.title = "Mesh ($strnbtriangles triangles)"
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


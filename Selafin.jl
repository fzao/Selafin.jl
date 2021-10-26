using GLMakie
using Dates

insertcommas(num::Integer) = replace(string(num), r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => ",")

# initialization
filesizeunit = Dict("Byte" => 1, "KB" => 1024, "MB" => 1048576, "GB" => 1073741824, "TB" => 1099511627776)
oksymbol = Char(0x2713)
noksymbol = Char(0x274E)
smallsquare = Char(0x25AA)
delta = Char(0x394)

# open the Selafin file
#filename = "malpasset.slf"
#filename = "mersey.slf"
filename = "girxl2d_result.slf"
#filename = "a9.slf"
bytesize = filesize(filename)
if bytesize == 0
    error("$noksymbol The file $filename does not exist")
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
println("$oksymbol File $filename of size: $intreadbytesize $sizeunit")
fid = open(filename, "r")

# read: Title
rec = ntoh(read(fid, Int32))
title = String(read(fid, rec))
rec = ntoh(read(fid, Int32))
title = lstrip(rstrip(title))
println("$oksymbol Name of the simulation: $title")

# read: Number of variables
rec = ntoh(read(fid, Int32))
nbvars = ntoh(read(fid, Int32))

# read: Number of xvar
nbxvar = ntoh(read(fid, Int32))
rec = ntoh(read(fid, Int32))

# read: Variable names
varnames = String[]
for i in 1:nbvars
    localrec = ntoh(read(fid, Int32))
    push!(varnames, String(read(fid, localrec)))
    localrec = ntoh(read(fid, Int32))
end

# read: Forsegments (10 times 4 bytes is expected)
fmtid = ntoh(read(fid, Int32))
if fmtid != 40
    println("$noksymbol Unknown forsegments for data recording")
    exit(fmtid)
end

# read: Integer parameters
iparam = Int32[]
for i in 1:10
    push!(iparam, ntoh(read(fid, Int32)))
end
fmtid = ntoh(read(fid, Int32))

# read: Date
idate = Int32[]
if iparam[10] == 1
    rec = ntoh(read(fid, Int32))
    for i in 1:6
        push!(idate, ntoh(read(fid, Int32)))
    end
    rec = ntoh(read(fid, Int32))
end
checkdate = idate[1] * idate[2] * idate[3]
if checkdate == 0
    datehour = "Unknown"
else
    datehour = DateTime(idate[1], idate[2], idate[3], idate[4], idate[5], idate[6])
end
println("$oksymbol Event start date and time: $datehour")

# read: Number of layers
nblayers = iparam[7] != 0 ? iparam[7] : 1
dimtelemac = nblayers == 1 ? "2D" : "3D"
println("$oksymbol Telemac $dimtelemac results with $nbvars variables")
println("$oksymbol Variables are:")
for i = 1:nbvars
    if i < 10
        spacing = "  - "
    else
        spacing = " - "
    end
    vname = lowercase(lstrip(rstrip(varnames[i])))
    println("\t$i$spacing$vname")
end

# read: Mesh info (size)
rec = ntoh(read(fid, Int32))
nbtriangles =  ntoh(read(fid, Int32))
nbnodes =  ntoh(read(fid, Int32))
nbptelem =  ntoh(read(fid, Int32))
if nbptelem != 3
    println("$noksymbol Unknown type of mesh elements")
    exit(nbptelem)
end
unknown = ntoh(read(fid, Int32))
rec = ntoh(read(fid, Int32))
strnbtriangles = insertcommas(nbtriangles)
strnbnodes = insertcommas(nbnodes)
println("$oksymbol Unstructured mesh with $strnbtriangles triangles and $strnbnodes nodes")

# read: Mesh info (ikle connectivity)
rec = ntoh(read(fid, Int32))
ikle = zeros(nbptelem, nbtriangles)
ikle = [ntoh(read(fid, Int32)) for i in 1:nbptelem, j in 1:nbtriangles]
ikle = transpose(ikle)
rec = ntoh(read(fid, Int32))

# read: Mesh info (ipobo boundary nodes)
rec = ntoh(read(fid, Int32))
ipobo = zeros(nbnodes)
ipobo = [ntoh(read(fid, Int32)) for i in 1:nbnodes]
rec = ntoh(read(fid, Int32))

# read: Mesh info (xy coordinates)
rec = ntoh(read(fid, Int32))
typefloat = nbnodes * 4 == rec ? Float32 : Float64
x = Array{typefloat, 1}(undef, nbnodes)
x = [ntoh(read(fid, typefloat)) for i in 1:nbnodes]
rec = ntoh(read(fid, Int32))
rec = ntoh(read(fid, Int32))
y = Array{typefloat, 1}(undef, nbnodes)
y = [ntoh(read(fid, Float32)) for i in 1:nbnodes]
rec = ntoh(read(fid, Int32))

# read: Number of time steps
@time begin
markposition = mark(fid)
bytecount = bytesize - markposition
nbsteps = trunc(Int, bytecount / (nbvars * nbnodes * sizeof(typefloat)))
end

# read: Variables
reset(fid)
variables = Array{typefloat, 2}(undef, nbnodes, nbvars)
timevalue = Float32(0)
for t in 1:nbsteps
    recloc = ntoh(read(fid, Int32))
    global timevalue = ntoh(read(fid, Float32))
    recloc = ntoh(read(fid, Int32))
    for v in 1:nbvars
        recloc = ntoh(read(fid, Int32))
        variables[:,v] = [ntoh(read(fid, typefloat)) for i in 1:nbnodes]
        recloc = ntoh(read(fid, Int32))
    end
end
if nbsteps > 1
    timesteps = timevalue / (nbsteps - 1)
    println("\r$oksymbol Number of time steps: $nbsteps with "*"$delta"*"t = $timesteps s")
else
    println("\r$oksymbol Number of time steps: $nbsteps")
end


# close the Selafin file
close(fid)

# plot: Mesh
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
segments = unique(segments, dims=1)
segmentsize = size(segments)[1]
ptx = Array{Float32, 1}(undef, 3*segmentsize)
pty = Array{Float32, 1}(undef, 3*segmentsize)
k = 1
for i in 1:segmentsize
    pt1 = segments[i][1]
    pt2 = segments[i][2]
    ptx[k] = x[pt1]
    pty[k] = y[pt1]
    global k += 1
    ptx[k] = x[pt2]
    pty[k] = y[pt2]
    global k += 1
    ptx[k] = NaN
    pty[k] = NaN
    global k += 1
end

# plot
scene = lines(ptx, pty)
display(scene)
#=     plot(ptx,pty, legend = false,
           xlabel = "x-coordinates (m)",
           ylabel = "y-coordinates (m)",
           title = "Mesh with $nbtriangles triangles and $nbnodes nodes") =#


#= using GeometryBasics
rect = Rect(0., 0., 1., 1.)
msh = GeometryBasics.mesh(rect)
xy2 = collect(Iterators.flatten(xy))
points = GeometryBasics.Point2[xy2] =#

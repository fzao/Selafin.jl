function Read(filename)

    telemac_data = Data()
    telemac_data.filename = filename

    bytesize = filesize(telemac_data.filename)
    if bytesize == 0
        error("$noksymbol The file $(telemac_data.filename) does not exist")
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
    println("$oksymbol File $(telemac_data.filename) of size: $intreadbytesize $sizeunit")
    telemac_data.fid = open(telemac_data.filename, "r")

    # read: Title
    rec = ntoh(read(telemac_data.fid, Int32))
    telemac_data.title = String(read(telemac_data.fid, rec))
    rec = ntoh(read(telemac_data.fid, Int32))
    telemac_data.title = lstrip(rstrip(telemac_data.title))
    println("$oksymbol Name of the simulation: $(telemac_data.title)")

    # read: Number of variables (tri)
    rec = ntoh(read(telemac_data.fid, Int32))
    telemac_data.nbvars = ntoh(read(telemac_data.fid, Int32))

    # read: Number of variables (quad)
    nbqvars = ntoh(read(telemac_data.fid, Int32))
    rec = ntoh(read(telemac_data.fid, Int32))

    # read: Variable names
    telemac_data.varnames = String[]
    for i in 1:telemac_data.nbvars
        localrec = ntoh(read(telemac_data.fid, Int32))
        push!(telemac_data.varnames, String(read(telemac_data.fid, localrec)))
        localrec = ntoh(read(telemac_data.fid, Int32))
    end

    # read: Forsegments (10 times 4 bytes is expected)
    fmtid = ntoh(read(telemac_data.fid, Int32))
    if fmtid != 40
        println("$noksymbol Unknown forsegments for data recording")
        exit(fmtid)
    end

    # read: Integer parameters
    telemac_data.iparam = Int32[]
    for i in 1:10
        push!(telemac_data.iparam, ntoh(read(telemac_data.fid, Int32)))
    end
    fmtid = ntoh(read(telemac_data.fid, Int32))

    # read: Date
    telemac_data.idate = Int32[]
    checkdate = 0
    if telemac_data.iparam[10] == 1
        rec = ntoh(read(telemac_data.fid, Int32))
        for i in 1:6
            push!(telemac_data.idate, ntoh(read(telemac_data.fid, Int32)))
        end
        rec = ntoh(read(telemac_data.fid, Int32))
        checkdate = telemac_data.idate[1] * telemac_data.idate[2] * telemac_data.idate[3]
    end
    if checkdate == 0
        datehour = "Unknown"
    else
        datehour = Dates.format(DateTime(telemac_data.idate[1], telemac_data.idate[2], telemac_data.idate[3], telemac_data.idate[4], telemac_data.idate[5], telemac_data.idate[6]), "yyyy-mm-dd HH:MM:SS")
    end
    println("$oksymbol Event start date and time: $datehour")

    # read: Number of layers
    telemac_data.nblayers = telemac_data.iparam[7] != 0 ? telemac_data.iparam[7] : 1
    dimtelemac = telemac_data.nblayers == 1 ? "2D" : "3D"
    println("$oksymbol Telemac $dimtelemac results with $(telemac_data.nbvars) variables")
    println("$oksymbol Variables are:")
    for i = 1:telemac_data.nbvars
        if i < 10
            spacing = "  - "
        else
            spacing = " - "
        end
        vname = lowercase(lstrip(rstrip(telemac_data.varnames[i])))
        println("\t$i$spacing$vname")
    end

    # read: Mesh info (size)
    rec = ntoh(read(telemac_data.fid, Int32))
    telemac_data.nbtriangles =  ntoh(read(telemac_data.fid, Int32))
    telemac_data.nbnodes =  ntoh(read(telemac_data.fid, Int32))
    nbptelem =  ntoh(read(telemac_data.fid, Int32))
    if nbptelem != 3
        println("$noksymbol Unknown type of mesh elements")
        exit(nbptelem)
    end
    unknown = ntoh(read(telemac_data.fid, Int32))
    rec = ntoh(read(telemac_data.fid, Int32))
    strnbtriangles = insertcommas(telemac_data.nbtriangles)
    strnbnodes = insertcommas(telemac_data.nbnodes)
    println("$oksymbol Unstructured mesh with $strnbtriangles triangles and $strnbnodes nodes")

    # read: Mesh info (ikle connectivity)
    rec = ntoh(read(telemac_data.fid, Int32))
    telemac_data.ikle = zeros(Int32, nbptelem, telemac_data.nbtriangles)
    telemac_data.ikle = [ntoh(read(telemac_data.fid, Int32)) for i in 1:nbptelem, j in 1:telemac_data.nbtriangles]
    telemac_data.ikle = transpose(telemac_data.ikle)
    rec = ntoh(read(telemac_data.fid, Int32))

    # read: Mesh info (ipobo boundary nodes)
    rec = ntoh(read(telemac_data.fid, Int32))
    ipobo = zeros(Int32, telemac_data.nbnodes)
    ipobo = [ntoh(read(telemac_data.fid, Int32)) for i in 1:telemac_data.nbnodes]
    rec = ntoh(read(telemac_data.fid, Int32))

    # read: Mesh info (xy coordinates)
    rec = ntoh(read(telemac_data.fid, Int32))
    telemac_data.typefloat = telemac_data.nbnodes * 4 == rec ? Float32 : Float64
    telemac_data.x = Array{telemac_data.typefloat, 1}(undef, telemac_data.nbnodes)
    telemac_data.x = [ntoh(read(telemac_data.fid, telemac_data.typefloat)) for i in 1:telemac_data.nbnodes]
    rec = ntoh(read(telemac_data.fid, Int32))
    rec = ntoh(read(telemac_data.fid, Int32))
    telemac_data.y = Array{telemac_data.typefloat, 1}(undef, telemac_data.nbnodes)
    telemac_data.y = [ntoh(read(telemac_data.fid, Float32)) for i in 1:telemac_data.nbnodes]
    rec = ntoh(read(telemac_data.fid, Int32))

    # read: Number of time steps
    markposition = mark(telemac_data.fid)
    bytecount = bytesize - markposition
    telemac_data.nbsteps = trunc(Int, bytecount / (telemac_data.nbvars * telemac_data.nbnodes * sizeof(telemac_data.typefloat) + 8 * telemac_data.nbvars +8))

    # read: Variables
    reset(telemac_data.fid)
    variables = Array{telemac_data.typefloat, 2}(undef, telemac_data.nbnodes, telemac_data.nbvars)
    timevalue =  Array{Float32, 1}(undef, telemac_data.nbsteps)
    for t in 1:telemac_data.nbsteps
        recloc = ntoh(read(telemac_data.fid, Int32))
        timevalue[t] = ntoh(read(telemac_data.fid, Float32))
        recloc = ntoh(read(telemac_data.fid, Int32))
        for v in 1:telemac_data.nbvars
            recloc = ntoh(read(telemac_data.fid, Int32))
            raw_data = zeros(UInt8, recloc)
            readbytes!(telemac_data.fid, raw_data, recloc)
            variables[:, v] .= ntoh.(reinterpret(telemac_data.typefloat, raw_data))
            recloc = ntoh(read(telemac_data.fid, Int32))
        end
    end
    if telemac_data.nbsteps > 1
        telemac_data.timestep = timevalue[2] - timevalue[1]
        println("$oksymbol Number of time steps: $(telemac_data.nbsteps) with "*"$delta"*"t = $(telemac_data.timestep) s")
    else
        telemac_data.timestep = 0
        println("$oksymbol Number of time steps: $(telemac_data.nbsteps)")
    end

    # close the Selafin file
    close(telemac_data.fid)

    return telemac_data
end

# Read.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# Read parameters from a Selafin file name
# Return a data structure (Model.jl) containing all the information
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
    Read(filename)

    Read the Telemac result file in the Selafin format
    The return variable is a structure containing the main information about the Telemac file

    Use: 
        julia> data = Selafin.Read("T2Dresults.slf")
    
    # Arguments
        - `filename::String`: the path of the Telemac Selafin file
"""
function Read(filename, verbose=true)

    if typeof(filename) != String
        if verbose == true println("$(Parameters.noksymbol) Parameter for the file name is not a string") end
        return
    elseif !isfile(filename)
        if verbose == true println("$(Parameters.noksymbol) Selafin file does not exist") end
        return
    end

    telemac_data = Data()
    telemac_data.verbose = verbose
    telemac_data.filename = filename

    bytesize = filesize(telemac_data.filename)
    if bytesize == 0
        if telemac_data.verbose == true println("$noksymbol The file $(telemac_data.filename) does not exist") end
        return
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
        sizeunit = "TB"
    end
    intreadbytesize = UInt16(round(readbytesize))
    if telemac_data.verbose == true println("$(Parameters.oksymbol) File $(telemac_data.filename) of size: $intreadbytesize $sizeunit") end
    fid = open(telemac_data.filename, "r")

    # read: Title
    rec = ntoh(read(fid, Int32))
    telemac_data.title = String(read(fid, rec))
    rec = ntoh(read(fid, Int32))
    telemac_data.title = lstrip(rstrip(telemac_data.title))
    if telemac_data.verbose == true println("$(Parameters.oksymbol) Name of the simulation: $(telemac_data.title)") end

    # read: Number of variables (tri)
    rec = ntoh(read(fid, Int32))
    telemac_data.nbvars = ntoh(read(fid, Int32))

    # read: Number of variables (quad)
    nbqvars = ntoh(read(fid, Int32))
    rec = ntoh(read(fid, Int32))

    # read: Variable names
    telemac_data.varnames = String[]
    for i in 1:telemac_data.nbvars
        localrec = ntoh(read(fid, Int32))
        push!(telemac_data.varnames, String(read(fid, localrec)))
        localrec = ntoh(read(fid, Int32))
    end

    # read: Forsegments (10 times 4 bytes is expected)
    fmtid = ntoh(read(fid, Int32))
    if fmtid != 40
        if telemac_data.verbose == true 
            println("$(Parameters.noksymbol) Unknown forsegments for data recording")
            flush(stdout)
        end
        exit(fmtid)
    end

    # read: Integer parameters
    telemac_data.iparam = Int32[]
    for i in 1:10
        push!(telemac_data.iparam, ntoh(read(fid, Int32)))
    end
    fmtid = ntoh(read(fid, Int32))

    # read: Date
    telemac_data.idate = Int32[]
    checkdate = 0
    if telemac_data.iparam[10] == 1
        rec = ntoh(read(fid, Int32))
        for i in 1:6
            push!(telemac_data.idate, ntoh(read(fid, Int32)))
        end
        rec = ntoh(read(fid, Int32))
        checkdate = telemac_data.idate[1] * telemac_data.idate[2] * telemac_data.idate[3]
    end
    if checkdate == 0
        datehour = "Unknown"
    else
        datehour = Dates.format(DateTime(telemac_data.idate[1], telemac_data.idate[2], telemac_data.idate[3], telemac_data.idate[4], telemac_data.idate[5], telemac_data.idate[6]), "yyyy-mm-dd HH:MM:SS")
    end
    if telemac_data.verbose == true println("$(Parameters.oksymbol) Event start date and time: $datehour") end

    # read: Number of layers
    telemac_data.nblayers = telemac_data.iparam[7] != 0 ? telemac_data.iparam[7] : 1
    dimtelemac = telemac_data.nblayers == 1 ? "2D" : "3D"
    if dimtelemac == "2D"
        if telemac_data.verbose == true println("$(Parameters.oksymbol) Telemac 2D results with $(telemac_data.nbvars) variables") end
    else
        if telemac_data.verbose == true println("$(Parameters.oksymbol) Telemac 3D results with $(telemac_data.nbvars) variables and $(telemac_data.nblayers) layers") end
    end
    if telemac_data.verbose == true
        println("$(Parameters.oksymbol) Variables are:")
        for i = 1:telemac_data.nbvars
            if i < 10
                spacing = "  - "
            else
                spacing = " - "
            end
            vname = lowercase(lstrip(rstrip(telemac_data.varnames[i])))
            println("\t$i$spacing$vname")
        end
    end

    # read: Mesh info (size)
    rec = ntoh(read(fid, Int32))
    telemac_data.nbtriangles =  ntoh(read(fid, Int32))
    telemac_data.nbnodes =  ntoh(read(fid, Int32))
    nbptelem =  ntoh(read(fid, Int32))
    if (telemac_data.nblayers == 1 && nbptelem != 3) || (telemac_data.nblayers != 1 && nbptelem != 6)
        if telemac_data.verbose == true 
            println("$(Parameters.noksymbol) Unknown type of mesh elements")
            flush(stdout)
        end
        exit(nbptelem)
    end
    unknown = ntoh(read(fid, Int32))
    rec = ntoh(read(fid, Int32))
    if telemac_data.nblayers == 1
        telemac_data.nbtrianglesLayer = telemac_data.nbtriangles
        telemac_data.nbnodesLayer = telemac_data.nbnodes
    else
        telemac_data.nbtrianglesLayer = Int32(telemac_data.nbtriangles / (telemac_data.nblayers - 1))
        telemac_data.nbnodesLayer = Int32(telemac_data.nbnodes / telemac_data.nblayers)
    end
    strnbtriangles = insertcommas(telemac_data.nbtrianglesLayer)
    strnbnodes = insertcommas(telemac_data.nbnodesLayer)
    if telemac_data.verbose == true println("$(Parameters.oksymbol) Unstructured mesh with $strnbtriangles triangles and $strnbnodes nodes") end

    # read: Mesh info (ikle connectivity)
    rec = ntoh(read(fid, Int32))
    telemac_data.ikle = zeros(Int32, nbptelem, telemac_data.nbtriangles)
    telemac_data.ikle = [ntoh(read(fid, Int32)) for i in 1:nbptelem, j in 1:telemac_data.nbtriangles]
    telemac_data.ikle = transpose(telemac_data.ikle)
    rec = ntoh(read(fid, Int32))

    # read: Mesh info (ipobo boundary nodes)
    rec = ntoh(read(fid, Int32))
    ipobo = zeros(Int32, telemac_data.nbnodes)
    ipobo = [ntoh(read(fid, Int32)) for i in 1:telemac_data.nbnodes]
    rec = ntoh(read(fid, Int32))

    # read: Mesh info (xy coordinates)
    rec = ntoh(read(fid, Int32))
    telemac_data.typefloat = telemac_data.nbnodes * 4 == rec ? Float32 : Float64
    telemac_data.x = Array{telemac_data.typefloat, 1}(undef, telemac_data.nbnodes)
    telemac_data.x = [ntoh(read(fid, telemac_data.typefloat)) for i in 1:telemac_data.nbnodes]
    rec = ntoh(read(fid, Int32))
    rec = ntoh(read(fid, Int32))
    telemac_data.y = Array{telemac_data.typefloat, 1}(undef, telemac_data.nbnodes)
    telemac_data.y = [ntoh(read(fid, Float32)) for i in 1:telemac_data.nbnodes]
    rec = ntoh(read(fid, Int32))

    # read: Number of time steps
    markposition = mark(fid)
    telemac_data.markposition = markposition
    bytecount = bytesize - markposition
    telemac_data.nbsteps = trunc(Int, bytecount / (telemac_data.nbvars * telemac_data.nbnodes * sizeof(telemac_data.typefloat) + 8 * telemac_data.nbvars +8))

    # read: Variables
    reset(fid)
    timevalue =  Array{Float32, 1}(undef, telemac_data.nbsteps)
    for t in 1:telemac_data.nbsteps
        recloc = ntoh(read(fid, Int32))
        timevalue[t] = ntoh(read(fid, Float32))
        recloc = ntoh(read(fid, Int32))
        for v in 1:telemac_data.nbvars
            recloc = ntoh(read(fid, Int32))
            raw_data = zeros(UInt8, recloc)
            readbytes!(fid, raw_data, recloc)
            recloc = ntoh(read(fid, Int32))
        end
    end
    if telemac_data.nbsteps > 1
        firststep = timevalue[2] - timevalue[1]
        if telemac_data.nbsteps > 2
            telemac_data.timestep = timevalue[3] - timevalue[2]
        else
            telemac_data.timestep = firststep
        end
        if telemac_data.verbose == true println("$(Parameters.oksymbol) Number of time steps: $(telemac_data.nbsteps) with "*"$delta"*"t = $(telemac_data.timestep) s") end
        if telemac_data.timestep != firststep
            if telemac_data.verbose == true println("$(Parameters.exclam) The first time step is different ($(firststep) s) due to a shifted recording of results") end
        end
    else
        telemac_data.timestep = 0
        if telemac_data.verbose == true println("$(Parameters.oksymbol) Number of time steps: $(telemac_data.nbsteps)") end
    end

    # close the Selafin file
    close(fid)

    return telemac_data
end

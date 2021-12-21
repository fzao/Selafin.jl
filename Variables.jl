function Get(data)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end

    fid = open(data.filename, "r")
    seek(fid, data.markposition)

    variables = Array{data.typefloat, 2}(undef, data.nbnodes, data.nbvars)
    timevalue =  Array{Float32, 1}(undef, data.nbsteps)
    for t in 1:data.nbsteps
        recloc = ntoh(read(fid, Int32))
        timevalue[t] = ntoh(read(fid, Float32))
        recloc = ntoh(read(fid, Int32))
        for v in 1:data.nbvars
            recloc = ntoh(read(fid, Int32))
            raw_data = zeros(UInt8, recloc)
            readbytes!(fid, raw_data, recloc)
            variables[:, v] .= ntoh.(reinterpret(data.typefloat, raw_data))
            recloc = ntoh(read(fid, Int32))
        end
    end

    # close the Selafin file
    close(fid)

    return variables
end

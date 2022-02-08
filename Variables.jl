function Get(data, novar=0, notime=0, figopt=false, figname=nothing)

    if typeof(data) != Data
        println("$(Parameters.noksymbol) Parameter is not a Data struct")
        return
    end
    if novar <= 0
        println("$(Parameters.noksymbol) The variable number is not positive")
        return
    elseif novar > data.nbvars
        println("$(Parameters.noksymbol) The variable number exceeds the number of recorded variables")
        return
    end
    if notime <= 0
        println("$(Parameters.noksymbol) The time number is not positive")
        return
    elseif notime > data.nbsteps
        println("$(Parameters.noksymbol) The time number exceeds the number of records")
        return
    end

    fid = open(data.filename, "r")
    seek(fid, data.markposition)

    variables = Array{data.typefloat, 1}(undef, data.nbnodes)
    timevalue =  Array{Float32, 1}(undef, data.nbsteps)
    exitloop = false
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
            if t == notime && v == novar
                exitloop = true
                break
            end
        end
        if exitloop
            break
        end
    end

    # close the Selafin file
    close(fid)

    # statistics
    minval = round(minimum(variables), digits = 2)
    meanval = round(mean(variables), digits = 2)
    medval = round(median(variables), digits = 2)
    maxval = round(maximum(variables), digits = 2)
    println("$(Parameters.oksymbol) Read variable #$(novar) at time record #$(notime) with:")
    println("\t Min. value: $minval")
    println("\t Max. value: $maxval")
    println("\t Mean: $meanval")
    println("\t Median: $medval")

    if figopt
        fig = Figure()
        Axis(fig[1, 1], title=data.varnames[novar], xlabel = "x-coordinates (m)", ylabel = "y-coordinates (m)")
        Colorbar(fig[1, 2], limits = (minimum(variables), maximum(variables)), colormap = :viridis)
        mesh!([data.x data.y], data.ikle, color=variables, colormap=:viridis, shading=false)

        if !isnothing(figname)
            save(figname, fig, px_per_unit = 2)
        end

        display(fig)
    end

    return variables
end

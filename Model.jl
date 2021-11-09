module Model

    export Data

    mutable struct Data
        filename:: String  # Selafin file path
        fid::IOStream  # file identifier
        title::String  # name of the study
        nbvars::Int32  # number of variables
        varnames::Array{String, 2}  # names of variables
        iparam::Array{Int32, 1}  # integer parameters
        idate::Array{Int32, 1}  # date info
        nblayers::Int32  # number of layers
        nbtriangles::Int32  # number of mesh triangles
        nbnodes::Int32  # number of mesh nodes
        ikle::Array{Int32, 2}  # mesh connectivity
    end

end

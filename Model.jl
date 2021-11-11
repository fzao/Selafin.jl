module Model

    export Data

    mutable struct Data
        fid::IOStream  # file identifier
        filename:: String  # Selafin file path
        title::String  # name of the study
        nbvars::Int32  # number of variables
        nblayers::Int32  # number of layers
        nbtriangles::Int32  # number of mesh triangles
        nbnodes::Int32  # number of mesh nodes
        nbsteps::Int32  # number of time steps
        timestep::Int32  # time step in seconds
        varnames  # names of variables
        typefloat  # simple or double precision
        iparam::Array{Int32, 1}  # integer parameters
        idate::Array{Int32, 1}  # date info
        ikle::Array{Int32, 2}  # mesh connectivity
        x::Array{Float64, 1}  # mesh x-coordinates
        y::Array{Float64, 1}  # mesh y-coordinates

        Data() = new()
    end

end

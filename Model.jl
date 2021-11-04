module Model

    export Data

    mutable struct Data
        filename:: String  # Selafin file path
        fid::IOStream  # file identifier
        title::String  # name of the study
        nbvars::Int32  # number of variables
        varnames::Array{String, 2}  # names of variables
        iparam::Array{Int32, 1}  # integer parameters
    end

end

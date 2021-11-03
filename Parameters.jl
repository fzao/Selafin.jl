module Parameters

    export filesizeunit, oksymbol, noksymbol, smallsquare, delta, superscripttwo, eps, minqualval

    # the number of bytes of different units
    const filesizeunit = Dict("Byte" => 1, "KB" => 1024, "MB" => 1048576, "GB" => 1073741824, "TB" => 1099511627776)
    
    # some UTF-8 characters  codes
    const oksymbol = Char(0x2713)
    const noksymbol = Char(0x274E)
    const smallsquare = Char(0x25AA)
    const delta = Char(0x394)
    const superscripttwo = Char(0x00B2)

    # numerical zero value
    const eps = 1.e-6

    # default criteria for detecting bad triangles
    const minqualval = 0.5

end
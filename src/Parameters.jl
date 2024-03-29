# Parameters.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
#
# Some constant values
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
    const hand = Char(0x270B)
    const le = Char(0x2264)
    const ge = Char(0x2265)
    const circle = Char(0x25CF)
    const triright = Char(0x022B3)
    const bigtimes = Char(0x02A09)
    const exclam = Char(0x2757)

    # numerical zero value
    const eps = 1.e-6

    # default criteria for detecting bad triangles
    const minqualval = 0.5

    # colorscheme
    scientific = [:acton, :bamako, :batlow, :berlin, :bilbao, :broc, :buda, :cork, :davos, :devon, :grayC, :hawaii, :imola, :lajolla, :lapaz, :lisbon, :nuuk, :oleron, :oslo, :roma, :tofino, :tokyo, :turku, :vik, :viridis]

end
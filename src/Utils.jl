# Utils.jl : this file is a part of the Selafin.jl project (a reader and viewer of the Telemac Selafin file (www.opentelemac.org) in the Julia programming language)
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
module Utils

    export insertcommas, convertSeconds

    insertcommas(num::Integer) = replace(string(num), r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => ",")

    function convertSeconds(seconds)

        days = seconds ÷ 86400
        hours = (seconds ÷ 3600) - (days * 24)
        minutes = (seconds ÷ 60) - (days * 1440) - (hours * 60)
        seconds = seconds % 60

        return string(days)*"d:"*string(hours)*"h:"*string(minutes)*"m:"*string(seconds)*'s'
    end

end
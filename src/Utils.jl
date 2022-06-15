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

    export insertcommas, convertSeconds, linearreg, findnum, interiorTriangle, interpolInTriangle

    insertcommas(num::Integer) = replace(string(num), r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => ",")

    function convertSeconds(seconds)

        days = seconds ÷ 86400
        hours = (seconds ÷ 3600) - (days * 24)
        minutes = (seconds ÷ 60) - (days * 1440) - (hours * 60)
        seconds = seconds % 60

        return string(days)*"d:"*string(hours)*"h:"*string(minutes)*"m:"*string(seconds)*'s'
    end

    function linearreg(x, y)
        n = length(x)
        a = (n * sum(x .* y)- sum(x) * sum(y)) / (n * sum(x.^2) - sum(x).^2)  # slope
        b = (sum(y) * sum(x.^2) - sum(x) * sum(x .* y)) / (n * sum(x.^2) - sum(x)^2)  # intercept
        return a, b
    end

    function findnum(data, node)
        for i in 1:data.nblayers
            a = (i-1) * data.nbnodesLayer + 1
            b = i * data.nbnodesLayer
            if node >= a && node <= b
                return i, node - a + 1  # noplane, nodenum
            end
        end
    end

    function Orient(Ax, Ay, Bx, By, Cx, Cy)
        ABx = Bx - Ax
        ABy = By - Ay
        ACx = Cx - Ax
        ACy = Cy - Ay
        crossprod = ABx * ACy - ABy * ACx
        if crossprod >= 0.
            return 1
        else
            return 0
        end
    end
    
    function interiorTriangle(data, Px, Py)
        numtri = nothing
        for i in 1:data.nbtrianglesLayer
            A = data.ikle[i, 1]
            B = data.ikle[i, 2]
            C = data.ikle[i, 3]
            Ax = data.x[A]; Ay = data.y[A]
            Bx = data.x[B]; By = data.y[B]
            Cx = data.x[C]; Cy = data.y[C]
            totor = 0
            totor = Orient(Ax, Ay, Bx, By, Px, Py)
            totor += Orient(Bx, By, Cx, Cy, Px, Py)
            totor += Orient(Cx, Cy, Ax, Ay, Px, Py)
            if totor == 3
                numtri = i
                break
            end
        end
        return numtri
    end
    
    function interpolInTriangle(data, A, B, C, valA, valB, valC, P)
        Ax = data.x[A]; Ay = data.y[A]
        Bx = data.x[B]; By = data.y[B]
        Cx = data.x[C]; Cy = data.y[C]
        Px = P[1]; Py = P[2]
        den = 1. / ((By - Cy) * (Ax - Cx) + (Cx - Bx) * (Ay - Cy))
        w1 = ((By - Cy) * (Px - Cx) + (Cx - Bx) * (Py - Cy)) * den
        w2 = ((Cy - Ay) * (Px - Cx) + (Ax - Cx) * (Py - Cy)) * den
        w3 = 1. - w1 - w2
        return w1 * valA + w2 * valB + w3 * valC
    end

end
module Norm2

    export distance

    function distance(x1::T, y1::T, x2::T, y2::T) where {T<:Number}

        return sqrt((x1 - x2) * (x1 - x2) +
                    (y1 - y2) * (y1 - y2))

    end

end
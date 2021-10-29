module Distance

    export euclidean, euclidean2

    function euclidean(x1::T, y1::T, x2::T, y2::T) where {T<:Number}
        return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
    end

    function euclidean2(x1::T, y1::T, x2::T, y2::T) where {T<:Number}
        return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
    end

end
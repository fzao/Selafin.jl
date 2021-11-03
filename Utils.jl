module Utils

    export insertcommas

    insertcommas(num::Integer) = replace(string(num), r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => ",")

end
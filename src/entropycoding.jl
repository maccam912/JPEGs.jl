const coords = [
(1,1),
(1,2),(2,1),
(3,1),(2,2),(1,3),
(1,4),(2,3),(3,2),(4,1),
(5,1),(4,2),(3,3),(2,4),(1,5),
(1,6),(2,5),(3,4),(4,3),(5,2),(6,1),
(7,1),(6,2),(5,3),(4,4),(3,5),(2,6),(1,7),
(1,8),(2,7),(3,6),(4,5),(5,4),(6,3),(7,2),(8,1),
(8,2),(7,3),(6,4),(5,5),(4,6),(3,7),(2,8),
(3,8),(4,7),(5,6),(6,5),(7,4),(8,3),
(8,4),(7,5),(6,6),(5,7),(4,8),
(5,8),(6,7),(7,6),(8,5),
(8,6),(7,7),(6,8),
(7,8),(8,7),
(8,8),
]

struct DCACBlock
    DC::Int64
    AC::Vector{Int64}
end

function zigzag(x::Matrix)::Vector
    values = []
    for c in coords
        push!(values, x[c...])
    end
    return values
end

function unzigzag(x::Vector)::Matrix
    retval = zeros(8,8)
    for (i,v) in enumerate(x)
        retval[coords[i]...] = v
    end
    return retval
end

function value_to_dc_code(v::Int64)::Tuple{UInt8,BitArray}
    if v == 0
        return (0,[])
    else
        numbits = Int64(floor(log2(abs(v))))+1
        bits = []
        if v > 0
            bits = [parse(Int64, i) for i in string(v, base=2)]
        else
            bits = [parse(Int64, i) for i in string(abs(v), base=2)]
            bits = 1 .- bits
        end
        return numbits,bits
    end
end

function dc_code_to_value(numbits,bits::BitArray)::Int64
    if numbits == 0
        return 0
    else
        if bits[1] == 1
            s = *([i ? "1" : "0" for i in bits]...)
            v = parse(Int64,s,base=2)
            return v
        else
            s = *([i ? "0" : "1" for i in bits]...)
            v = parse(Int64,s,base=2)
            return -1*v
        end
    end
end

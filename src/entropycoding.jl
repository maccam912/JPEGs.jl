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
    DC::Int
    AC::Vector{Int}
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

function value_to_dc_code(v::Int)::Tuple{Int,BitArray}
    if v == 0
        return (0,[])
    else
        numbits = Int(floor(log2(abs(v))))+1
        bits = []
        if v > 0
            bits = [parse(Int, i) for i in string(v, base=2)]
        else
            bits = [parse(Int, i) for i in string(abs(v), base=2)]
            bits = 1 .- bits
        end
        return numbits,bits
    end
end

function dc_code_to_value(numbits,bits::BitArray)::Int
    if numbits == 0
        return 0
    else
        if bits[1] == 1
            s = *([i ? "1" : "0" for i in bits]...)
            v = parse(Int,s,base=2)
            return v
        else
            s = *([i ? "0" : "1" for i in bits]...)
            v = parse(Int,s,base=2)
            return -1*v
        end
    end
end

function length_to_huffman_string(b::Int)::BitArray
    d::Dict{Int,BitArray} = Dict(
    0=>[0,0],
    1=>[0,1,0],
    2=>[0,1,1],
    3=>[1,0,0],
    4=>[1,0,1],
    5=>[1,1,0],
    6=>[1,1,1,0],
    7=>[1,1,1,1,0],
    8=>[1,1,1,1,1,0],
    9=>[1,1,1,1,1,1,0],
    10=>[1,1,1,1,1,1,1,0],
    11=>[1,1,1,1,1,1,1,1,0],
    )
    return d[b]
end

function huffman_string_to_length(b::BitArray)::Union{Int,Nothing}
    try
        d::Dict{BitArray,Int} = Dict(
        [0,0]=>0,
        [0,1,0]=>1,
        [0,1,1]=>2,
        [1,0,0]=>3,
        [1,0,1]=>4,
        [1,1,0]=>5,
        [1,1,1,0]=>6,
        [1,1,1,1,0]=>7,
        [1,1,1,1,1,0]=>8,
        [1,1,1,1,1,1,0]=>9,
        [1,1,1,1,1,1,1,0]=>10,
        [1,1,1,1,1,1,1,1,0]=>11,
        )
        return d[b]
    catch
        return nothing
    end
end

function value_to_dc_bits(v::Int)::BitArray
    l, bits = value_to_dc_code(v)
    ls = length_to_huffman_string(l)
    return vcat(ls,bits)
end

function bits_to_dc_value(b::BitArray)::Int
    l = nothing
    ls::BitArray = []
    while isnothing(l)
        push!(ls,popfirst!(b))
        l = huffman_string_to_length(ls)
    end
    dcbits = copy(b[1:l])
    for i=1:l
        popfirst!(b)
    end
    return dc_code_to_value(l,dcbits)
end

function ac_value_to_bits(v::Int)::BitArray
    return [1,1,0,0]
end

function bits_to_ac_value(b::BitArray)::Int
    return 0
end

function encode_zigzagged_block(x::Vector)::BitArray
    dc = x[1]
    dcarray = value_to_dc_bits(dc)
    ac = x[2:end]
    return vcat(dcarray, [1, 1, 0, 0])
end

function decode_zigzagged_block(x::BitArray)::Vector{Int}
    v = bits_to_dc_value(x)
    a = zeros(63)
    idx = 1
    while x[1:4] != [1,1,0,0]
        #parse ac
        acval = bits_to_ac_value(x)
        a[idx] = acval
        idx += 1
    end
    for i=1:4
        popfirst!(x)
    end
    return vcat([v], a)
end

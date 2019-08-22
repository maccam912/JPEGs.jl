function byte_to_bits(b::UInt8)::BitArray
    retval = []
    push!(retval, (b&0b10000000)/128)
    push!(retval, (b&0b01000000)/64)
    push!(retval, (b&0b00100000)/32)
    push!(retval, (b&0b00010000)/16)
    push!(retval, (b&0b00001000)/8)
    push!(retval, (b&0b00000100)/4)
    push!(retval, (b&0b00000010)/2)
    push!(retval, (b&0b00000001))
    return retval
end

function decode_jpeg_data(jpeg::JPEG)
    bytes = []
    for segment in jpeg.segments
        if typeof(segment) == SOS
            bytes = segment.bytes
        end
    end
    bits = vcat(byte_to_bits.(bytes)...)
    h,w = get_jpeg_hw(jpeg)

    num_mcus = Int64(round((h*w)/64))
    dc_y = get_huffman_table(jpeg, 0, 0)
    ac_y = get_huffman_table(jpeg, 1, 0)
    dc_c = get_huffman_table(jpeg, 0, 1)
    ac_c = get_huffman_table(jpeg, 1, 1)
    dcs = [dc_y, dc_c]
    acs = [ac_y, ac_c]
    for mcu_num in 1:num_mcus
        RLE = zeros(8,8,3)
        decoded = []
        for component=1:2#y and color components
            println("Component $component")
            dc_table = dcs[component]
            ac_table = acs[component]
            bits_scanned::BitArray = []
            if length(bits_scanned) > 16
                println("too long!")
                break
            end
            while length(bits) > 0
                #check for huffman code
                v = check(bits_scanned, dc_table)
                if !isnothing(v)
                    push!(decoded, (v[1],v[2]))
                    bits_scanned = []
                end
                push!(bits_scanned, popfirst!(bits))
            end

        end
    end
    println(num_mcus)
    k = 1
end

function check(b::BitArray, table::Dict{Tuple{Int64,UInt16},UInt8})::Union{Nothing,Tuple}
    l = length(b)
    v = 0
    for i=1:l
        v += b[i]
        v *= 2
    end
    v /= 2
    key = (l, v)
    if haskey(table, key)
        println("Found key!")
        println(key)
        value = table[key]
        zeroCount = (value&0b11110000)/16
        category = (value&0b00001111)
        return zeroCount,category
    end
end

#https://www.impulseadventure.com/photo/jpeg-huffman-coding.html

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
    dc_y = get_huffman_table(jpeg, 0, 0)
    ac_y = get_huffman_table(jpeg, 1, 0)
    dc_c = get_huffman_table(jpeg, 0, 1)
    ac_c = get_huffman_table(jpeg, 1, 1)
    bytes = []
    for segment in jpeg.segments
        if typeof(segment) == SOS
            bytes = segment.bytes
        end
    end
    #println(typeof(jpeg.segments))
    bits = vcat(byte_to_bits.(bytes)...)
    h,w = get_jpeg_hw(jpeg)
    k = 1
    blocks = []
    num_mcus = Int64(round((h*w)/64))
    for mcu in 1:num_mcus
        for c in [:Y, :Cb, :Cr]
            tables = []
            if c == :Y
                tables = [dc_y, ac_y]
            else
                tables = [dc_c, ac_c]
            end
            for tabletype in [:DC, :AC]
                curr_table = Dict()
                if tabletype == :DC
                    curr_table = tables[1]
                else
                    curr_table = tables[2]
                end
                #println("c: $c, tabletype: $tabletype")
                #@show(curr_table)
                subbits::BitArray = []
                while k <= length(bits)
                    #println(bits[k:end])
                    push!(subbits, bits[k])
                    k += 1
                    if length(subbits) > 16
                        println("c: $c, tabletype: $tabletype")
                        println("SUBBITS TOO LONG. $subbits")
                        jpeg.mcus = blocks
                        return
                    end
                    #if isnothing(curr_table)
                    #    push!(blocks, (mcu, c, tabletype, 0))
                    #    break
                    #else
                        v = check(subbits, curr_table)
                        if !isnothing(v)
                            if v == 0x00 && tabletype == :AC
                                push!(blocks, (mcu, c, tabletype, 0))
                                break
                            end
                            nextn = []
                            for i=1:v
                                push!(nextn, bits[k])
                                k += 1
                            end
                            dcvalue = dc_value_lookup(nextn)
                            #@show(dcvalue)
                            push!(blocks, (mcu, c, tabletype, dcvalue))
                            if tabletype == :DC
                                break
                            else
                                subbits = []
                            end
                        end
                    #end
                end
            end
        end
    end
    jpeg.mcus = fix_dcvals(blocks)

end

function fix_dcvals(mcus)
    newmcus = []
    rel_value = 0
    for mcu in mcus
        if mcu[3] == :DC
            newmcu = (mcu[1], mcu[2], mcu[3], rel_value+mcu[4])
            push!(newmcus, newmcu)
            rel_value = newmcu[4]
        end
    end
    return newmcus
end

function bitarraytoint(ba::BitArray)
    retval = 0
    for i in ba
        retval += i
        retval *= 2
    end
    return retval/2
end

function check(b, n::Nothing)
    return 0
end

function check(b::BitArray, table::Dict{Tuple{Int64,UInt16},UInt8})::Union{Nothing,UInt8}
    l = length(b)
    v = 0
    for i=1:l
        v += b[i]
        v *= 2
    end
    v /= 2
    key = (l, v)
    if haskey(table, key)
        value = table[key]
        return value
    end
end

function dc_value_lookup(nextn)
    #println(nextn)
    if length(nextn) == 0
        return 0
    elseif length(nextn) == 1 && nextn[1] == 0
        return -1
    elseif length(nextn) == 1 && nextn[1] == 1
        return 1
    else
        minposvalue = 2^(length(nextn)-1)
        maxposvalue = 2*minposvalue-1
        positive = (nextn[1] == 1)
        remainingbits::BitArray = nextn[2:end]
        asint = bitarraytoint(remainingbits)
        if !positive
            return asint+(-1*maxposvalue)
        else
            return asint+minposvalue
        end
    end
end

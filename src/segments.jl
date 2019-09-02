function pack_bits(b::BitArray)::Vector{UInt8}
    paddingsize = 8 - (length(b) % 8)
    with_padding = b
    if paddingsize > 0
        padding::BitArray = ones(paddingsize)
        with_padding = vcat(b, padding)
    end
    bytes = []
    for bidx=1:8:length(with_padding)-8
        subarray = b[bidx:bidx+7]
        str = *([x ? "1" : "0" for x in subarray]...)
        push!(bytes, parse(UInt8, str, base=2))
    end
    return bytes
end

function unpack_bits(v::Vector{UInt8})::BitArray
    b::BitArray = []
    for byte in v
        for char in lpad(string(byte, base=2), 8, '0')
            push!(b, char == '1' ? 1 : 0)
        end
    end
    @assert length(v) == length(b)/8
    return b
end

function segments_into_bytes(s::Vector{Vector{UInt8}})
    bytes = []
    for segment in s
        push!(bytes, segment)
    end
    return vcat(bytes...)
end

function split_into_segments(b::Vector{UInt8})::Vector{Vector{UInt8}}
    markers = []
    for i=1:length(b)-1
        if b[i] == 0xFF && b[i+1] != 0x00
            push!(markers, i)
        end
    end
    segments = []
    for m=1:length(markers)-1
        start = markers[m]
        stop = markers[m+1]-1
        push!(segments, b[start:stop])
    end
    push!(segments, b[markers[end]:end])
    return segments
end

function embed_jpeg_scan(scan::BitArray)::Vector{Vector{UInt8}}
    @assert scan[end-3:end] == [1,1,0,0]
    soi = [0xFF, 0xD8]
    eoi = [0xFF, 0xD9]
    scan_seg = [
    0xFF, 0xDA, #Marker
    0x00, 0x0C, #Length
    0x03, #Number of Components
    0x01, 0x00, #Y component
    0x02, 0x11, #Cb component
    0x03, 0x11, #Cr component
    0x00, 0x00, 0x00 # mandatory skip these
    ]
    sos_data = pack_bits(scan)
    fixed_scan_data = []
    for b in sos_data
        push!(fixed_scan_data, b)
        if b == 0xFF
            push!(fixed_scan_data, 0x00) # Sincd 0xFF is used for markers, add 0x00 after a 0xFF in scan data
        end
    end
    with_scan_data = vcat(scan_seg, fixed_scan_data)
    return [soi, with_scan_data, eoi]
end

function extract_jpeg_scan(jpeg::Vector{Vector{UInt8}})::BitArray
    with_scan_data = jpeg[2]
    scan_data = with_scan_data[15:end]
    fixed_scan_data::Vector{UInt8} = []
    idx = 1
    while idx <= length(scan_data)
        push!(fixed_scan_data, scan_data[idx])
        if scan_data[idx] == 0xFF && scan_data[idx+1] == 0x00
            idx +=1
        end
        idx += 1
    end
    bits = unpack_bits(fixed_scan_data)
    return bits
end

function serialize_jpeg_scan(scan::BitArray)::Vector{UInt8}
    return segments_into_bytes(embed_jpeg_scan(scan))
end

function deserialize_into_jpeg_scan(v::Vector{UInt8})::BitArray
    jpeg_scan = extract_jpeg_scan(split_into_segments(v))
    return jpeg_scan
end

module JPEGs
# May thanks to http://imrannazar.com/Let%27s-Build-a-JPEG-Decoder%3A-File-Structurw


abstract type JPEGSegment end

struct JPEG
    segments::Vector{JPEGSegment}
    pixels::Union{Nothing,Array{UInt8,3}}
end

include("HuffmanDecoder.jl")

struct SOI <: JPEGSegment end
struct EOI <: JPEGSegment end

mutable struct DQT <: JPEGSegment
    data::Vector{UInt8}
end

mutable struct DHT <: JPEGSegment
    data::Vector{UInt8}
    dcac::Union{Nothing,Int64}
    destination_id::Union{Nothing,Int64}
    counts::Union{Nothing,Dict{Int64,Int64}}
    values::Union{Nothing,Vector{UInt8}}
    table::Union{Nothing,Dict{Tuple{Int64,UInt16},UInt8}}
end

function DHT(v::Vector{UInt8})::DHT
    return DHT(v, nothing, nothing, nothing, nothing, nothing)
end

struct SOFComponent
    id::Int64
    sampling_resolution::Int64
    quantization_table::Int64
end

mutable struct SOF <: JPEGSegment
    data::Vector{UInt8}
    precision::Union{Nothing,Int64}
    width::Union{Nothing,Int64}
    height::Union{Nothing,Int64}
    numcomponents::Union{Nothing,Int64}
    components::Union{Nothing,Vector{SOFComponent}}
end

struct SOSComponentData
    id::Int64
    ht_dc_destination::Int64
    ht_ac_destination::Int64
end

struct SOSHeader
    length::Int64
    components::Int64
    component_data::Vector{SOSComponentData}
    skipbytes::Vector{UInt8}
end

mutable struct SOS <: JPEGSegment
    data::Vector{UInt8}
    header::Union{Nothing,SOSHeader}
    bytes::Union{Nothing,Vector{UInt8}}
end

function decode_bytes(b::Vector{UInt8})
    segments = get_segments(b)
    jpeg = JPEG(segments, nothing)
    parse_sof(jpeg)
    parse_sos(jpeg)
    decode_jpeg_data(jpeg)
    return jpeg
end

function get_segments(b::Vector{UInt8})::Vector{JPEGSegment}
    segments::Vector{JPEGSegment} = []
    idx = 1
    while idx < length(b)
        data::Vector{UInt8} = []
        if b[idx:idx+1] == [0xFF,0xD8]
            push!(segments, SOI())
        elseif b[idx:idx+1] == [0xFF,0xDB]
            while b[idx+1] != 0xFF || b[idx+2] == 0x00
                push!(data, b[idx])
                idx += 1
            end
            push!(data, b[idx])
            push!(segments, DQT(data))
        elseif b[idx:idx+1] == [0xFF,0xC4]
            while b[idx+1] != 0xFF || b[idx+2] == 0x00
                push!(data, b[idx])
                idx += 1
            end
            push!(data, b[idx])
            dht = DHT(data)
            decode_dht(dht)
            push!(segments, dht)
        elseif b[idx:idx+1] == [0xFF,0xC0]
            while b[idx+1] != 0xFF || b[idx+2] == 0x00
                push!(data, b[idx])
                idx += 1
            end
            push!(data, b[idx])
            push!(segments, SOF(data, nothing, nothing, nothing, nothing, nothing))
        elseif b[idx:idx+1] == [0xFF,0xDA]
            while b[idx+1] != 0xFF || (b[idx+2] == 0x00 || (b[idx+2] > 0xD0 && b[idx+2] < 0xD7))
                push!(data, b[idx])
                idx += 1
            end
            push!(data, b[idx])
            push!(segments, SOS(data, nothing, nothing))
        elseif b[idx:idx+1] == [0xFF,0xD9]
            push!(segments, EOI())
            break
        end
        idx += 1
    end
    return segments
end

function decode_dht(s::DHT)
    counts = Dict()
    dcoracandhtdestinationid = s.data[5]
    dcorac = (dcoracandhtdestinationid & 0b00010000) / 16
    htdestinationid = (dcoracandhtdestinationid & 0b00000001)
    s.dcac = dcorac
    s.destination_id = htdestinationid
    numvals = 0
    for i=1:16
        if s.data[i+5] > 0
            counts[i] = s.data[i+5]
            numvals += s.data[i+5]
        else
            counts[i] = 0
        end
    end
    s.counts = counts
    s.values = s.data[22:end]
    build_dht_table(s)
end

function build_dht_table(s::DHT)
    table = Dict()
    code = 0
    count = 1
    for i=1:16
        for j=1:s.counts[i]
            table[(i, code)] = s.values[count]
            count += 1
            code += 1
        end
        code *= 2
    end
    s.table = table
end

function parse_sof(jpeg::JPEG)
    for segment in jpeg.segments
        if typeof(segment) == JPEGs.SOF
            bytes = segment.data[5:end]
            segment.precision = bytes[1]
            segment.height = bytes[2]*256+bytes[3]
            segment.width = bytes[4]*256+bytes[5]
            segment.numcomponents = bytes[6]
            segment.components = []
            for i=1:segment.numcomponents
                c = parse_component(bytes[4+3i:end])
                push!(segment.components, c)
            end
        end
    end
end

function parse_component(b::Vector{UInt8})
    id=b[1]
    sampling_resolution=b[2]
    quantization_table=b[3]
    return SOFComponent(id, sampling_resolution, quantization_table)
end

function parse_sos(jpeg::JPEG)
    for segment in jpeg.segments
        if typeof(segment) == SOS
            bytes = segment.data[3:end]
            bytesstart, h = parse_sos_header(bytes)
            segment.header = h
            segment.bytes = bytes[bytesstart:end]
            segment.bytes = smoosh_segment_bytes(segment.bytes)
        end
    end
end

function parse_sos_header(b::Vector{UInt8})
    length = b[1]*256+b[2]
    components = b[3]
    components_array = []
    for i=1:components
        nb = b[2+2i:2+2i+1]
        c = parse_sos_component(nb)
        push!(components_array, c)
    end
    sbidx = 2+2components+1+1
    skipbytes = b[sbidx:sbidx+2]
    #skipbytes = rawskipbytes[1]*256*256+rawskipbytes[2]*256+rawskipbytes[3]
    @assert(sbidx+3 == 13)
    return sbidx+3, SOSHeader(length, components, components_array, skipbytes)
end

function parse_sos_component(b::Vector{UInt8})
    id = b[1]
    ht_dc_destination = (b[2]&0b00010000)/16
    ht_ac_destination = (b[2]&0b00000001)
    return SOSComponentData(id, ht_dc_destination, ht_ac_destination)
end

function smoosh_segment_bytes(b::Vector{UInt8})::Vector{UInt8}
    newb = []
    i = 1
    while i < length(b)
        push!(newb, b[i])
        if b[i]==0xFF && b[i+1] == 0x00
            i += 1
        end
        i += 1
    end
    return newb
end

function get_jpeg_hw(jpeg::JPEG)
    for segment in jpeg.segments
        if typeof(segment) == SOF
            return (segment.height, segment.width)
        end
    end
end

function get_jpeg_components(jpeg::JPEG)
    for segment in jpeg.segments
        if typeof(segment) == SOF
            return segment.numcomponents
        end
    end
end

function get_huffman_table(jpeg::JPEG, dc::Int64, y::Int64)
    for segment in jpeg.segments
        if typeof(segment) == DHT && segment.dcac == dc && segment.destination_id == y
            return segment.table
        end
    end
end

end

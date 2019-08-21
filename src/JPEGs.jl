module JPEGs
# May thanks to http://imrannazar.com/Let%27s-Build-a-JPEG-Decoder%3A-File-Structurw

abstract type JPEGSegment end

struct SOI <: JPEGSegment end
struct EOI <: JPEGSegment end

struct DQT <: JPEGSegment
    data::Vector{UInt8}
end

mutable struct DHT <: JPEGSegment
    data::Vector{UInt8}
    table_id::Union{Nothing,Int64}
    counts::Union{Nothing,Dict{Int64,Int64}}
    values::Union{Nothing,Vector{UInt8}}
end

function DHT(v::Vector{UInt8})::DHT
    return DHT(v, nothing, nothing, nothing)
end

struct SOF <: JPEGSegment
    data::Vector{UInt8}
end

struct SOS <: JPEGSegment
    data::Vector{UInt8}
end

function decode_bytes(b::Vector{UInt8})
    segments = get_segments(b)
    return segments
end

function get_segments(b::Vector{UInt8})::Vector{JPEGSegment}
    segments::Vector{JPEGSegment} = []
    idx = 1
    while idx < length(b)
        data::Vector{UInt8} = []
        if b[idx:idx+1] == [0xFF,0xD8]
            push!(segments, SOI())
        elseif b[idx:idx+1] == [0xFF,0xDB]
            while b[idx+1] != 0xFF
                push!(data, b[idx])
                idx += 1
            end
            push!(data, b[idx])
            push!(segments, DQT(data))
        elseif b[idx:idx+1] == [0xFF,0xC4]
            while b[idx+1] != 0xFF
                push!(data, b[idx])
                idx += 1
            end
            push!(data, b[idx])
            dht = DHT(data)
            decode_dht(dht)
            push!(segments, dht)
        elseif b[idx:idx+1] == [0xFF,0xC0]
            while b[idx+1] != 0xFF
                push!(data, b[idx])
                idx += 1
            end
            push!(data, b[idx])
            push!(segments, SOF(data))
        elseif b[idx:idx+1] == [0xFF,0xDA]
            while b[idx+1] != 0xFF
                push!(data, b[idx])
                idx += 1
            end
            push!(data, b[idx])
            push!(segments, SOS(data))
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
    numvals = 0
    for i=1:16
        if s.data[i+5] > 0
            counts[i] = s.data[i+5]
            numvals += s.data[i+5]
        end
    end
    s.counts = counts
    println(numvals)
    s.values = s.data[22:end]
end

end

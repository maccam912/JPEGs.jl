module JPEGs

include("color_space_transformation.jl")
include("downsampling.jl")
include("block_splitting.jl")
include("dct.jl")
include("quantization.jl")
include("entropycoding.jl")
include("segments.jl")

function encode_image(img::Array{ColorTypes.RGB{FixedPointNumbers.Normed{UInt8,8}},2})
    i2 = JPEGs.rgb_to_ycbcr(img)
    y,cb,cr = JPEGs.split_channels(i2)
    #dcb = JPEGs.downsample_4_2_0(cb)
    #dcr = JPEGs.downsample_4_2_0(cr)
    y = JPEGs.split_into_blocks(y)
    cb = JPEGs.split_into_blocks(cb)
    cr = JPEGs.split_into_blocks(cr)
    y = JPEGs.dct.(y)
    cb = JPEGs.dct.(cb)
    cr = JPEGs.dct.(cr)

    y = JPEGs.quantize.(y)
    cb = JPEGs.quantize.(cb)
    cr = JPEGs.quantize.(cr)
    y = JPEGs.zigzag.(y)
    cb = JPEGs.zigzag.(cb)
    cr = JPEGs.zigzag.(cr)
    encoded_y = JPEGs.encode_zigzagged_block.(y)
    encoded_cb = JPEGs.encode_zigzagged_block.(cb)
    encoded_cr = JPEGs.encode_zigzagged_block.(cr)
    interlaced = [vcat(i...) for i in zip(encoded_y, encoded_cb, encoded_cr)]
    flattened = reshape(interlaced, *(size(interlaced)...))
    encoded_blocks = vcat(flattened...)
    serialized = JPEGs.serialize_jpeg_scan(encoded_blocks)
    return serialized
end

function decode_image(serialized_jpeg::Vector{UInt8})#::Array{ColorTypes.RGB{FixedPointNumbers.Normed{UInt8,8}},2}
    allbits = JPEGs.deserialize_into_jpeg_scan(serialized_jpeg)
    decoded_blocks = []
    while length(decoded_blocks) < (64*64*3)-1
        if length(decoded_blocks) == 12287
            println(allbits)
        end
        push!(decoded_blocks, decode_zigzagged_block(allbits))
    end
    y = []
    cb = []
    cr = []
    for b in 1:3:length(decoded_blocks)
        push!(y, JPEGs.unzigzag(decoded_blocks[b]))
        push!(cb, JPEGs.unzigzag(decoded_blocks[b+1]))
        push!(cr, JPEGs.unzigzag(decoded_blocks[b+2]))
    end
    y = JPEGs.unquantize.(y)
    cb = JPEGs.unquantize.(cb)
    cr = JPEGs.unquantize.(cr)
    y = JPEGs.invdct.(y)
    cb = JPEGs.invdct.(cb)
    cr = JPEGs.invdct.(cr)
    y = reshape(y, (64,64))
    cb = reshape(cb, (64,64))
    cr = reshape(cr, (64,64))
    y = JPEGs.join_blocks(y)
    cb = JPEGs.join_blocks(cb)
    cr = JPEGs.join_blocks(cr)
    i2 = JPEGs.join_channels((y,cb,cr))
    img = JPEGs.ycbcr_to_rgb(i2)
    return img
end

end

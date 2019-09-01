module JPEGs

include("color_space_transformation.jl")
include("downsampling.jl")
include("block_splitting.jl")
include("dct.jl")
include("quantization.jl")
include("entropycoding.jl")

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
    encoded_blocks = vcat(encode_zigzagged_block.(y)...)

    return encoded_blocks
end

function decode_image(ybits)::Array{ColorTypes.RGB{FixedPointNumbers.Normed{UInt8,8}},2}
    decoded_blocks = []
    while length(ybits) > 0
        push!(decoded_blocks, decode_zigzagged_block(ybits))
    end
    y = JPEGs.unzigzag.(decoded_blocks)
    #cb = JPEGs.unzigzag.(cb)
    #cr = JPEGs.unzigzag.(cr)
    y = JPEGs.unquantize.(y)
    #cb = JPEGs.unquantize.(cb)
    #cr = JPEGs.unquantize.(cr)
    y = JPEGs.invdct.(y)
    #cb = JPEGs.invdct.(cb)
    cb = [Block(zeros(8,8)) for _ in 1:length(y)]
    #cr = JPEGs.invdct.(cr)
    cr = [Block(zeros(8,8)) for _ in 1:length(y)]
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

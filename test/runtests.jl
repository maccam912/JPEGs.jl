using Revise, JPEGs, FileIO, Plots
using Test

img = load("mandrill.tiff")
i2 = JPEGs.rgb_to_ycbcr(img)
y,cb,cr = JPEGs.split_channels(i2)
downsampled_y = JPEGs.downsample_4_2_0(y)

test_subimg = [
[52 55 61 66 70 61 64 73];
[63 59 55 90 109 85 69 72];
[62 59 68 113 144 104 66 73];
[63 58 71 122 154 106 70 69];
[67 61 68 104 126 88 68 70];
[79 65 60 70 77 68 58 75];
[85 71 64 59 55 61 64 83];
[87 79 69 68 65 76 78 94];
]

test_block = JPEGs.Block(test_subimg)
dctd = JPEGs.dct(test_block)
quantized = JPEGs.quantize(dctd)
zigzagged = JPEGs.zigzag(quantized)

# test color conversion
@assert JPEGs.ycbcr_to_rgb(JPEGs.rgb_to_ycbcr(img)) == img

# test splitting and joining channels
@assert JPEGs.join_channels(JPEGs.split_channels(i2)) == i2

# test upsampling and downsampling
@assert JPEGs.downsample_4_2_0(JPEGs.upsample_4_2_0(downsampled_y)) == downsampled_y

# test splitting into blocks and rejoining
@assert JPEGs.join_blocks(JPEGs.split_into_blocks(y)) == y

# test dct and idct
@assert JPEGs.invdct(JPEGs.dct(test_block)).data == test_block.data

# Test quantizing and unquantizing
@assert JPEGs.quantize(JPEGs.unquantize(quantized)) == quantized

# Test zigzagging
@assert JPEGs.unzigzag(JPEGs.zigzag(quantized)) == quantized

# Test dc value to int and back
for i=-2047:2047
    @assert JPEGs.dc_code_to_value(JPEGs.value_to_dc_code(i)...) == i
end

# Test huffman string encoding of dc values
for i=0:11
    @assert JPEGs.huffman_string_to_length(JPEGs.length_to_huffman_string(i)) == i
end

# Test converting value to dc coded bitstring and back
for i=-2047:2047
    @assert JPEGs.bits_to_dc_value(JPEGs.value_to_dc_bits(i)) == i
end

# Test joining and splitting segments
soi = [0xFF, 0xD8]
something = [0xFF, 0xD4]
joined = [soi, something]
@assert JPEGs.split_into_segments(JPEGs.segments_into_bytes(joined)) == joined

bytearray = [0xAA, 0xBB, 0xCC, 0xDD]
@assert JPEGs.pack_bits(JPEGs.unpack_bits(bytearray)) == bytearray

testscan = BitArray([1,1,1,1,0,0,0,0])
@assert testscan == JPEGs.deserialize_into_jpeg_scan(JPEGs.serialize_jpeg_scan(testscan))

bytes = JPEGs.encode_image(img)
i3 = JPEGs.decode_image(bytes)

function timing()
    allbits = JPEGs.encode_image(img)
    i3 = JPEGs.decode_image(allbits)
end
#@benchmark timing()

plot(i3)

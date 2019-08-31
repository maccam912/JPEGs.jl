using Revise, JPEGs, FileIO, Plots
using Test

img = load("test/lena5.jpg")
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

y,cb,cr = JPEGs.encode_image(img)
i3 = JPEGs.decode_image(y,cb,cr)

plot(i3)

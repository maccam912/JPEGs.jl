using ColorTypes, FixedPointNumbers

# Color space transformation
function rgb_to_ycbcr(pic::Array{ColorTypes.RGB{FixedPointNumbers.Normed{UInt8,8}},2})::Matrix{YCbCr{Float32}}
    return YCbCr.(pic)
end

function ycbcr_to_rgb(pic::Array{ColorTypes.YCbCr{Float32},2})::Array{ColorTypes.RGB{FixedPointNumbers.Normed{UInt8,8}},2}
    return RGB.(pic)
end

function split_channels(pic::Array{ColorTypes.YCbCr{Float32},2})::Tuple{Matrix{Float32},Matrix{Float32},Matrix{Float32}}
    ys = []
    cbs = []
    crs = []
    ys = map(x -> x.y, pic)
    cbs = map(x -> x.cb, pic)
    crs = map(x -> x.cr, pic)
    return (ys, cbs, crs)
end

function join_channels(x::Tuple{Matrix{Float32},Matrix{Float32},Matrix{Float32}})::Array{ColorTypes.YCbCr{Float32},2}
    retimg = Matrix{Tuple{Float32,Float32,Float32}}(undef, size(x[1]))
    for i=1:size(x[1])[1], j=1:size(x[1])[2]
        retimg[i,j] = (x[1][i,j], x[2][i,j], x[3][i,j])
    end
    return map(x -> YCbCr(x...), retimg)
end

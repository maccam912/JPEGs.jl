using Statistics

#lossy
function downsample_4_2_0(x::Matrix{Float32})::Matrix{Float32}
    retimg = Matrix{Float32}(undef, Int.(size(x)./2))
    for i=1:Int(size(x)[1]/2), j=1:Int(size(x)[2]/2)
        block_lower = 2*i
        block_upper = block_lower-1
        block_right = 2*j
        block_left = block_right-1
        subimg = x[block_upper:block_lower,block_left:block_right]
        retimg[i,j] = mean(subimg)
    end
    return retimg
end

function upsample_4_2_0(x::Matrix{Float32})::Matrix{Float32}
    retimg = Matrix{Float32}(undef, (size(x).*2))
    for i=1:Int(size(x)[1]), j=1:Int(size(x)[2])
        block_lower = 2*i
        block_upper = block_lower-1
        block_right = 2*j
        block_left = block_right-1
        thisval = x[i,j]
        retimg[block_upper:block_lower,block_left:block_right] .= thisval
    end
    return retimg
end

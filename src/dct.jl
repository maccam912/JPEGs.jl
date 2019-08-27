using FFTW

function recenter_block(x::Block)
    return Block(x.data .- 128)
end

function decenter_block(x::Block)
    return Block(x.data .+ 128)
end

function dct(g::Block)::Matrix{Float32}
    rg = recenter_block(g).data
    return FFTW.dct(rg)
end

function invdct(g::Matrix{Float32})::Block
    rg = round.(FFTW.idct(g))
    b = decenter_block(Block(rg))
    return b
end

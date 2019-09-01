mutable struct Block # MCU
    data::Matrix{Float32}
end

function split_into_blocks(x::Matrix{Float32}; blocksize=8)::Matrix{Block}
    blocks::Matrix{Block} = map(x->Block(Matrix{Float32}(undef, (blocksize,blocksize))), zeros(Int.(size(x)./blocksize)...))
    for (idxi,i)=enumerate(1:blocksize:size(x)[1]), (idxj,j)=enumerate(1:blocksize:size(x)[2])
        block = blocks[idxi,idxj]
        for (idxii,ii)=enumerate(i:i+(blocksize-1)), (idxjj,jj)=enumerate(j:j+(blocksize-1))
            block.data[idxii,idxjj] = x[ii,jj]
        end
    end
    return blocks
end

function join_blocks(x::Matrix{Block}; blocksize=8)::Matrix{Float32}
    retimg = Matrix{Float32}(undef, Int.(size(x).*blocksize))
    for (idxi,i)=enumerate(1:blocksize:size(retimg)[1]), (idxj,j)=enumerate(1:blocksize:size(retimg)[2])
        block = x[idxi,idxj]
        for (idxii,ii)=enumerate(i:i+blocksize-1), (idxjj,jj)=enumerate(j:j+blocksize-1)
            retimg[ii,jj] = block.data[idxii,idxjj]
        end
    end
    return retimg
end

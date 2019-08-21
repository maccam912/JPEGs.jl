using Revise, JPEGs
using Test

JPEGs.hello()

function test()
    f::Vector{UInt8} = read(open("test/rip.jpg", "r"))
    dims = JPEGs.decode(f)
    return dims
end

h = test()

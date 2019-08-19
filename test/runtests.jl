using Revise, JPEGs
using Test

JPEGs.hello()

function test()
    f::Vector{UInt8} = read(open("test/rip.jpg", "r"))
    rval = JPEGs.decode(f)
    return rval
end

h = test()

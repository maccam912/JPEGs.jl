module JPEGs

const deps_file = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(deps_file)
    error("JPEGs.jl is not installed properly, run Pkg.build(\"JPEGs\") and restart Julia.")
end
include(deps_file)

function __init__()
    check_deps()
end

function hello()
    ccall((:hello, rsjpegs), Cvoid, ())
end

function decode(b::Vector{UInt8})
    ccall((:decode, rsjpegs), UInt8, (Ref{UInt8}, UInt64), b, length(b))
end

end

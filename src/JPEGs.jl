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
    ccall((:hello, librsjpegs), Cvoid, ())
end

struct RSVec
    ptr::Ptr{UInt8}
    len::UInt64
    cap::UInt64
    data::Vector{UInt64}
end

function decode(b::Vector{UInt8})
    val = ccall((:decode, librsjpegs), Ptr{RSVec}, (Ptr{UInt8}, UInt64), b, length(b))
    loaded_val::RSVec = unsafe_load(val)
    v1::UInt8 = unsafe_load(loaded_val.ptr)
    println(v1)
    v1 = unsafe_load(loaded_val.ptr)
    println(v1)
    v1 = unsafe_load(loaded_val.ptr)
    println(v1)
    v1 = unsafe_load(loaded_val.ptr)
    println(v1)
    return loaded_val
end

end

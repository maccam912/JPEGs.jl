module JPEGs

struct nj_vlc_code_t
    bits::UInt8
    code::UInt8
end

struct nj_component_t
    cid::Int64
    ssx::Int64
    ssy::Int64
    width::Int64
    height::Int64
    stride::Int64
    qtsel::Int64
    actabsel::Int64
    dctabsel::Int64
    dcpred::Int64
    pixels::Vector{UInt8}
end

struct nj_context_t
    error::Int64
    spos::String
    pos::Vector{UInt8}
    size::Int64
    length::Int64
    width::Int64
    height::Int64
    mbwidth::Int64
    mbheight::Int64
    mbsizex::Int64
    mbsizey::Int64
    ncomb::Int64
    comp::Tuple{nj_component_t, nj_component_t, nj_component_t}
    qtused::Int64
    qtavail::Int64
    qtab::Vector{Vector{UInt8}}
    vlctab::Vector{nj_vlc_code_t}
    buf::Int64
    bufbits::Int64
    block::Vector{Int64}
    rstinterval::Int64
    rgb::Vector{UInt8}
end

njct = nj_component_t(0,0,0,0,0,0,0,0,0,0,[])
nj = nj_context_t(0, "", [0], 0, 0, 0, 0, 0, 0, 0, 0, 0, (njct, njct, njct), 0, 0, [[0],[0],[0],[0]], [], 0, 0, [0], 0, [])

njZZ = [ 0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18,
11, 4, 5, 12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6, 7, 14, 21, 28, 35,
42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51, 58, 59, 52, 45,
38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63 ]

njClip(x) = clamp(x, 0, 0xFF)

W1 = 2841
W2 = 2676
W3 = 2408
W5 = 1609
W6 = 1108
W7 = 565

function njRowIDCT(blk, p)
    x1 =  blk[p+4] << 11
    x2 = blk[p+6]
    x3 = blk[p+2]
    x4 = blk[p+1]
    x5 = blk[p+7]
    x6 = blk[p+5]
    x7 = blk[p+3]
    if !(|(x1, x2, x3, x4, x5, x6, x7))
        v = blk[p] << 3
        blk[p:p+7] .= v
        return
    end

    x0 = (blk[p] << 11) + 128
    x8 = W7 * (x4 + x5)
    x4 = x8 + (W1 - W7) * x4
    x5 = x8 - (W1 + W7) * x5
    x8 = W3 * (x6 + x7)
    x6 = x8 - (W3 - W5) * x6
    x7 = x8 - (W3 + W5) * x7
    x8 = x0 + x1
    x0 -= x1

    x1 = W6 * (x3 + x2)
    x2 = x1 - (W2 + W6) * x2
    x3 = x1 + (W2 - W6) * x3
    x1 = x4 + x6
    x4 -= x6

    x6 = x5 + x7
    x5 -= x7

    x7 = x8 + x3
    x8 -= x3

    x3 = x0 + x2
    x0 -= x2

    x2 = (181 * (x4 + x5) + 128) >> 8
    x4 = (181 * (x4 - x5) + 128) >> 8
    blk[p] = (x7 + x1) >> 8
    blk[p+1] = (x3 + x2) >> 8
    blk[p+2] = (x0 + x4) >> 8
    blk[p+3] = (x8 + x6) >> 8
    blk[p+4] = (x8 - x6) >> 8
    blk[p+5] = (x0 - x4) >> 8
    blk[p+6] = (x3 - x2) >> 8
    blk[p+7] = (x7 - x1) >> 8
end

end

end

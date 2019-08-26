using Revise, JPEGs
using Test

jpegbytes = read(open("test/smallimage.jpg", "r"))
jpeg = JPEGs.decode_bytes(jpegbytes)

for i=1:length(jpegbytes)-1
    if jpegbytes[i:i+1] == [0xff, 0xc1]
        println("DHT $i")
    end
end

@benchmark load("test/lena5.jpg"; view=true)

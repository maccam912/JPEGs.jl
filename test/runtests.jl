using Revise, JPEGs
using Test

jpegbytes = read(open("test/smallimage.jpg", "r"))
jpeg = JPEGs.decode_bytes(jpegbytes)

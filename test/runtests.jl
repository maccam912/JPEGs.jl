using Revise, JPEGs
using Test

jpegbytes = read(open("test/test.jpg", "r"))
jpeg = JPEGs.decode_bytes(jpegbytes)

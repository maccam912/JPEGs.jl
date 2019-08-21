using Revise, JPEGs
using Test

jpegbytes = read(open("test/test.jpg", "r"))
segments = JPEGs.decode_bytes(jpegbytes)

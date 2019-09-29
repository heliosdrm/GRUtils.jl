# Create example data
x = LinRange(0, 30, 1000)
y = cos.(x) .* x
z = sin.(x) .* x
# Draw a solid line and another with star markers
# in one of every 10 points
plot3(x, y, z, x[1:10:end], y[1:10:end], z[1:10:end], "p")

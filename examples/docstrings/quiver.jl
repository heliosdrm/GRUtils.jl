# Create example data
x = repeat(LinRange(-2, 2, 20), inner=10)
y = repeat(LinRange(-1, 1, 10), outer=20)
u = x .* (x.^2 .+ y.^2)
v = y .* (x.^2 .+ y.^2)
# Plot arrows
quiver(x, y, u, y, arrowscale=0.1)

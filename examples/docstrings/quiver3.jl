# Create example data
x = repeat(LinRange(-2, 2, 20), inner=10)
y = repeat(LinRange(0, pi, 10), outer=20)
z = sin.(x) .+ cos.(y)
u = 0.1ones(200)
v = zeros(200)
w = 0.5z
# Plot vectors
quiver3(x, y, z, u, v, w, "o", markersize=0.5)

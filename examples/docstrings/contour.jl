# 1. Create example point data
x = 8 .* rand(100) .- 4
y = 8 .* rand(100) .- 4
z = sin.(x) + cos.(y)
# Contour plot on the left without color (lines labelled by default)
subplot(1, 2, 1)
contour(x, y, z, colorbar = false)
# 2. Create example grid data with a callable
x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
f(x, y) = sin(x) + cos(y)
# Contour plot on the right with color
# and explicit labels every three lines
subplot(1, 2, 2)
contour(x, y, f, majorlevels = 3)

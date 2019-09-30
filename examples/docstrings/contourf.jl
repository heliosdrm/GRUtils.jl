# 1. Create example point data
x = 8 .* rand(100) .- 4
y = 8 .* rand(100) .- 4
z = sin.(x) + cos.(y)
# Contour plot
contourf(x, y, z)
# 2. Create example grid data with a callable
x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
f(x, y) = sin(x) + cos(y)
# Contour plot with 25 lines, labelling a quarter of them
contourf(x, y, f, levels = 25, majorlevels = 4)

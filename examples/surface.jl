# Create example grid data with a callable
x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
# Surface plot
surface(x, y, z)

# Create example point data
x = 8 .* rand(100) .- 4
y = 8 .* rand(100) .- 4
z = sin.(x) + cos.(y)
# Use the "hot" colormap
colormap("hot")
contourf(x, y, z)

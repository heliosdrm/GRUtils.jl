# Create example data
x = 2 .* rand(100) .- 1
y = 2 .* rand(100) .- 1
z = 2 .* rand(100) .- 1
c = 999 .* rand(100) .+ 1
# Plot the points with colors
scatter3(x, y, z, c)

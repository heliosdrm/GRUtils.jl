# Create example data
x = LinRange(0, 1, 11)
y = LinRange(0, 1, 11)
s = LinRange(50, 400, 11)
c = LinRange(0, 255, 11)
# Plot x and y
scatter(x, y)
# Add size and color to the points
scatter(x, y, s, c)

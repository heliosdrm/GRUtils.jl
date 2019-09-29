# Create example data
x = LinRange(-2, 2, 40)
y = x^3 + x^2 + x
# Plot x and y
stair(x, y)
# Plot y with indices for x values
stair(y)
# step directly after x each position
stair(y, where="pre")
# step between two x positions
stair(y, where="mid")
# step immediately before x each position
stair(y, where="post")

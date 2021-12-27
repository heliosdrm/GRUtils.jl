# Create example data
x = LinRange(-2, 2, 40)
y = x.^3 .+ x.^2 .+ x
# Plot x and y
stairs(x, y)
# Plot y with indices for x values
stairs(y)
# step directly after x each position
stairs(y, where="pre")
# step between two x positions
stairs(y, where="mid")
# step immediately before x each position
stairs(y, where="post")

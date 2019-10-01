# Create example data
x = LinRange(-2, 2, 40)
f(t) = t^3 + t^2 + t
y = f.(x)
# Plot x and y
plot(x, y)
# Plot x using the callable
plot(x, f)
# Plot y, using its indices for the x values
plot(y)
# Plot two columns
plot(x, [y 3x.^2 .- 3])
# Plot various series them with custom line specs
y2 = 3x.^2 .- 3
plot(x, y, "-r", x, y2, ":*b")

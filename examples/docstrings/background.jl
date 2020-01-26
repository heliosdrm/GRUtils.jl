# Create example data
x = LinRange(-2, 2, 40)
y = x.^3 .+ x.^2 .+ x
# Create a plot with light blue background
plot(x, y, backgroundcolor=0x88ccff)
# Remove the background
background(nothing)

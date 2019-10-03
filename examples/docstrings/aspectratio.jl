# Create example data
x = LinRange(-2, 2, 40)
y = x.^3 .+ x.^2 .+ x
# Draw a plot with panoramic ratio (16:9)
plot(x, y)
aspectratio(16/9)

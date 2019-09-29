# Create example data
x = LinRange(-2, 2, 40)
y = t.^3 .+ t.^2 .+ t
# Draw a plot with panoramic ratio (16:9)
plot(x, y)
aspectratio(16/9)

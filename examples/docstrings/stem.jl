# Create example data
x = LinRange(-2, 2, 40)
y = x.^3 .+ x.^2 .+ x .+ 6
# Plot x and y, with dashed stems ended in a star
stem(x, y, "--p")
# Move the baseline to 5
stem(x, y, baseline = 5)

# Create example data
x = LinRange(-2, 2, 40)
y = 2 .* x .+ 4
# Draw the first plot
plot(x, y)
# Plot another graph over it
oplot(x, x -> x^3 + x^2 + x)

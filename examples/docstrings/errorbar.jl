# Create example data
x = LinRange(-2, 2, 10)
y = x.^3 .+ x.^2 .+ x .+ 6
err = LinRange(0.5, 3, 10)
# Draw symmetric, horizontal error bars
errorbar(x, y, err, horizontal=true)
# Draw asymmetric error bars with markers
errorbar(x, y, err, err./2, "-o")

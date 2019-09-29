# Create example data
data = 2 .* randn(100) .- 1
# Draw the histogram with 19 bins
histogram(data, nbins=19)
# Horizontal histogram with log scale
histogram(data, horizontal=true, xlog=true)

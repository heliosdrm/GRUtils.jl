# Create line data with NaN as polyline separator
x = [randn(10000); NaN; randn(10000) .+ 5 ]
y = [randn(10000); NaN; randn(10000) .+ 5]
# Draw shade
shade(x, y, xform=3)

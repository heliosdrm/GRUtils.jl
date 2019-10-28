# Create example data
plot(-2π:0.01:2π, sin)
xlim(-2π, 2π)
ylim((-sqrt(2), sqrt(2)), true)
xticks(π/8, 4)
xticklabels(x -> @sprintf("%0.1f\\pi", float(x/π)))

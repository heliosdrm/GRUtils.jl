# Create example data
angle = LinRange(0, 2π, 40)
radius = LinRange(0, 10, 20)
z = sin.(angle') .* cos.(radius)
polarheatmap(z)

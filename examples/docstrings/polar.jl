# Create example data
angles = LinRange(0, 360, 40)
radii = LinRange(0, 2, 40)
# Draw the polar plot in degrees
polar(angles, radii, radians=false)

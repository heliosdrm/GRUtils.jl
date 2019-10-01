# Create example data
x = LinRange(-1, 1, 40)
y = LinRange(-1, 1, 40)
z = LinRange(-1, 1, 40)
v = 1 .- (x.^2 .+ y'.^2 .+ reshape(z,1,1,:).^2).^0.5 - 0.25 .* rand(40, 40, 40)
# Draw the 3d volume data using an emission model
volume(v, algorithm=2)

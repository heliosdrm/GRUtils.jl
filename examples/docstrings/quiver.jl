X = LinRange(-2, 2, 20)
Y = LinRange(-1, 1, 10)
x = (X .* ones(1, 10))[:]
y = (Y' .* ones(20))[:]
u = x .* vec(sqrt.(X'.^2 .+ Y.^2))
v = y .* vec(sqrt.(X'.^2 .+ Y.^2))
GRUtils.quiver(x, y, u, y, arrowscale=0.1)

using Test
using Random
using GRUtils

Random.seed!(111)

GRUtils.GR.inline("pdf")

x = 0.1(0:66) .- 3.3
f = t -> t^5 - 13*t^3 + 36*t
y = f.(x)
yy = [y y .+ 10x.^2]

plot(x, f)
plot(x, y)
plot(y)
plot(x, yy)
plot(yy)
plot(x .+ [-1 1], yy)

grid(false)
draw(gcf())

plot(-2π:0.01:2π, sin)
xlim(-2π, 2π)
ylim((-sqrt(2), sqrt(2)), true)
xticks(π/8, 4)
xticklabels(x -> Base.Printf.@sprintf("%0.1f\\pi", float(x/π)))
panzoom(0.4, 0)
xlim(); ylim()
zoom(1.5)

plot(x, y, ratio = 16//9)
oplot(x, x -> x^3 + x^2 + x)

x = LinRange(-2, 2, 40)
y = 2 .* x .+ 4
stair(x, y)
stair(x, x -> x^3 + x^2 + x)
stair(y)
stair(y, where="pre")
stair(y, where="mid")
stair(y, where="post")

x = LinRange(-2, 2, 40)
y = 0.2 .* x .+ 0.4
scatter(x, y)
scatter(x, x -> 0.2 * x + 0.4)
scatter(y)
x = LinRange(0, 1, 11)
y = LinRange(0, 1, 11)
s = LinRange(50, 400, 11)
c = LinRange(0, 255, 11)
scatter(x, y, s, c)

x = LinRange(-2, 2, 40)
y = 0.2 .* x .+ 0.4
stem(x, y)
stem(x, x -> x^3 + x^2 + x + 6)
stem(y)

x = LinRange(0, 30, 1000)
y = cos.(x) .* x
z = sin.(x) .* x
plot3(x, y, z)

angles = LinRange(0, 2pi, 40)
radii = LinRange(0, 2, 40)
polar(angles, radii)
polar(angles, r -> cos(r) ^ 2)

x = 2 .* rand(100) .- 1
y = 2 .* rand(100) .- 1
z = 2 .* rand(100) .- 1
c = 999 .* rand(100) .+ 1
# Plot the points
scatter3(x, y, z)
# Plot the points with colors
scatter3(x, y, z, c)

population = Dict("Africa" => 1216,
                 "America" => 1002,
                 "Asia" => 4436,
                 "Europe" => 739,
                 "Oceania" => 38)
barplot(keys(population), values(population))
barplot(keys(population), values(population), baseline=1000)
barplot(keys(population), values(population), baseline=500, ylog=true)
barplot(keys(population), values(population), horizontal=true)

x = 2 .* randn(100) .- 1
histogram(x)
histogram(x, ylog=true)
histogram(x, nbins=19)
histogram(x, horizontal=true)

x = 360 .* rand(100)
subplot(1,2,1)
histogram(x)
subplot(1,2,2)
polarhistogram(x, alpha=0.5)
subplot(1,2,1)
histogram(x, nbins=19)
subplot(1,2,2)
polarhistogram(x, nbins=19, alpha=0.5)

Figure()
x = LinRange(0, 1, 100)
plot(x, x.^2)
hold(true)
plot(x, x.^4, label="power 4")
plot(x, x.^8)
legend(location=11)
legend("square", location=2)
hold(false)

# Create example point data
x = 8 .* rand(100) .- 4
y = 8 .* rand(100) .- 4
f = (x,y) -> sin(x) + cos(y)
# Other
contour(x, y, z)
contour(x, y, z, levels=10)
contour(x, y, z, majorlevels=3)
contour(x, y, z, colorbar=false)
# Filled
contourf(x, y, z)
contourf(x, y, z, levels=10)
contourf(x, y, z, majorlevels=3)
contourf(x, y, z, colorbar=false)
# Tricontour
tricont(x, y, z)
tricont(x, y, z, levels=10)
tricont(x, y, z, colorbar=false)
# Surface
# surface(x, y, z) # gr3
trisurf(x, y, z)
# Create example grid data
x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y) # instead of # x, y = meshgrid(x, y)
# Draw the contour plot using a callable
contour(x, y, f)
contourf(x, y, z)
# surface(x, y, z) # gr3
# surface(x, y, z, accelerate=false) # compile gr3
wireframe(x, y, z)
heatmap(z)
polarheatmap(z)
imshow(z/4 .+ 0.5)

x = randn(100000)
y = randn(100000)
hexbin(x, y)

# s = LinRange(-4, 4, 50)
# v = cos.(s) .+ cos.(s)' .+ cos.(reshape(s,1,1,:))
# isosurface(v, 0.5, tilt=120, color=(0.6, 1.0, 0.85),
#     cameradistance=3.0, twist=12)

file_path = ENV["GKS_FILEPATH"]
@test isfile(file_path)
rm(file_path)

# Create point data
x = randn(100_000)
y = randn(100_000)
shade(x, y)
# Create line data with NaN as polyline separator
x = [randn(10000); NaN; randn(10000) .+ 5 ]
y = [randn(10000); NaN; randn(10000) .+ 5]
shade(x, y, xform=3)

# # Create example data
# x = LinRange(-1, 1, 40)
# y = LinRange(-1, 1, 40)
# z = LinRange(-1, 1, 40)
# v = 1 .- (x.^2 .+ y'.^2 .+ reshape(z,1,1,:).^2).^0.5 - 0.25 .* rand(40, 40, 40)
# # Draw the 3d volume data
# volume(v)
# # Draw the 3d volume data using an emission model
# volume(v, algorithm=2)

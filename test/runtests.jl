using Test
using GRUtils

x = 0.1(0:66) .- 3.3
f = t -> t^5 - 13*t^3 + 36*t
y = f.(x)
yy = [y y .+ 10x.^2]

GRUtils.plot(x, f)
GRUtils.plot(x, y)
GRUtils.plot(y)
GRUtils.plot(x, yy)
GRUtils.plot(yy)
GRUtils.plot(x .+ [-1 1], yy)

GRUtils.grid(false)
GRUtils.draw(GRUtils.gcf())

GRUtils.plot(-2π:0.01:2π, sin)
GRUtils.xlim(-2π, 2π)
GRUtils.ylim((-sqrt(2), sqrt(2)), true)
GRUtils.xticks(π/8, 4)
GRUtils.xticklabels(x -> Base.Printf.@sprintf("%0.1f\\pi", float(x/π)))
GRUtils.draw(GRUtils.gcf())


GRUtils.plot(x, y, ratio = 16//9)

x = LinRange(-2, 2, 40)
y = 2 .* x .+ 4
GRUtils.step(x, y)
GRUtils.step(x, x -> x^3 + x^2 + x)
GRUtils.step(y)
GRUtils.step(y, where="pre")
GRUtils.step(y, where="mid")
GRUtils.step(y, where="post")

x = LinRange(-2, 2, 40)
y = 0.2 .* x .+ 0.4
GRUtils.scatter(x, y)
GRUtils.scatter(x, x -> 0.2 * x + 0.4)
GRUtils.scatter(y)
x = LinRange(0, 1, 11)
y = LinRange(0, 1, 11)
s = LinRange(50, 400, 11)
c = LinRange(0, 255, 11)
GRUtils.scatter(x, y, s, c)

x = LinRange(-2, 2, 40)
y = 0.2 .* x .+ 0.4
GRUtils.stem(x, y)
GRUtils.stem(x, x -> x^3 + x^2 + x + 6)
GRUtils.stem(y)

x = LinRange(0, 30, 1000)
y = cos.(x) .* x
z = sin.(x) .* x
GRUtils.plot3(x, y, z)

angles = LinRange(0, 2pi, 40)
radii = LinRange(0, 2, 40)
GRUtils.polar(angles, radii)
GRUtils.polar(angles, r -> cos(r) ^ 2)

x = 2 .* rand(100) .- 1
y = 2 .* rand(100) .- 1
z = 2 .* rand(100) .- 1
c = 999 .* rand(100) .+ 1
# Plot the points
GRUtils.scatter3(x, y, z)
# Plot the points with colors
GRUtils.scatter3(x, y, z, c)

population = Dict("Africa" => 1216,
                 "America" => 1002,
                 "Asia" => 4436,
                 "Europe" => 739,
                 "Oceania" => 38)
GRUtils.barplot(keys(population), values(population))
GRUtils.barplot(keys(population), values(population), baseline=1000)
GRUtils.barplot(keys(population), values(population), baseline=500, ylog=true)
GRUtils.barplot(keys(population), values(population), horizontal=true)

x = 2 .* randn(100) .- 1
GRUtils.histogram(x)
GRUtils.histogram(x, ylog=true)
GRUtils.histogram(x, nbins=19)
GRUtils.histogram(x, horizontal=true)

x = 360 .* rand(100)
GRUtils.subplot(1,2,1)
GRUtils.histogram(x)
GRUtils.subplot(1,2,2)
GRUtils.polarhistogram(x, alpha=0.5)
GRUtils.subplot(1,2,1)
GRUtils.histogram(x, nbins=19)
GRUtils.subplot(1,2,2)
GRUtils.polarhistogram(x, nbins=19, alpha=0.5)

GRUtils.Figure()
x = LinRange(0, 1, 100)
GRUtils.plot(x, x.^2)
GRUtils.hold(true)
GRUtils.plot(x, x.^4, label="power 4")
GRUtils.plot(x, x.^8)
GRUtils.legend(location=11)
GRUtils.draw(GRUtils.gcf())
GRUtils.legend("square", location=2)
GRUtils.draw(GRUtils.gcf())
GRUtils.hold(false)

# Create example point data
x = 8 .* rand(100) .- 4
y = 8 .* rand(100) .- 4
f = (x,y) -> sin(x) + cos(y)
z = f.(x, y)
# Draw the contour plot using a callable
GRUtils.contour(x, y, f)
# Other
GRUtils.contour(x, y, z)
GRUtils.contour(x, y, z, levels=10)
GRUtils.contour(x, y, z, majorlevels=3)
GRUtils.contour(x, y, z, colorbar=false)
# Filled
GRUtils.contourf(x, y, z)
GRUtils.contourf(x, y, z, levels=10)
GRUtils.contourf(x, y, z, majorlevels=3)
GRUtils.contourf(x, y, z, colorbar=false)
# Tricontour
GRUtils.tricont(x, y, z)
GRUtils.tricont(x, y, z, levels=10)
GRUtils.tricont(x, y, z, colorbar=false)
# Surface
GRUtils.surface(x, y, z)
GRUtils.trisurf(x, y, z)
# Create example grid data
x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
# x, y = meshgrid(x, y)
z = sin.(x) .+ cos.(y')
# Draw the contour plot
GRUtils.contour(x, y, z)
GRUtils.contourf(x, y, z)
GRUtils.surface(x, y, z)
GRUtils.surface(x, y, z, accelerate=false)
GRUtils.wireframe(x, y, z)
GRUtils.heatmap(z)
GRUtils.polarheatmap(z)
GRUtils.imshow(z/4 .+ 0.5)

x = randn(100000)
y = randn(100000)
GRUtils.hexbin(x, y)

s = LinRange(-4, 4, 50)
v = cos.(s) .+ cos.(s)' .+ cos.(reshape(s,1,1,:))
GRUtils.isosurface(v, 0.5, tilt=120, color=(0.6, 1.0, 0.85),
    cameradistance=3.0, twist=12)

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

population = Dict("Africa" => 1216,
                 "America" => 1002,
                 "Asia" => 4436,
                 "Europe" => 739,
                 "Oceania" => 38)
GRUtils.barplot(keys(population), values(population))
GRUtils.barplot(keys(population), values(population), horizontal=true)

x = 2 .* randn(100) .- 1
GRUtils.histogram(x)
GRUtils.histogram(x, nbins=19)

GRUtils.polarhistogram(x, alpha=0.5)
GRUtils.polarhistogram(x, nbins=19, alpha=0.5)


x = LinRange(0, 1, 100)
GRUtils.plot(x, x.^2)
GRUtils.hold(true)
GRUtils.plot(x, x.^4, label="power 4")
GRUtils.plot(x, x.^8)
GRUtils.legend(location=11)
GRUtils.draw(GRUtils.gcf())
GRUtils.legend("square", location=2)
GRUtils.draw(GRUtils.gcf())

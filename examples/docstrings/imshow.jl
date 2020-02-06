# Create an image
x = LinRange(-3, 3, 150)
y = LinRange(-2, 2, 100)
# RGB values
r = ones(100) * (1 .+ cos.(x)')/2
g = (1 .+ sin.(exp.(x'.^2 .+ y.^2)))/2
b = exp.(y .- 2) * ones(1,150)
data = cat(r, g, b, dims=3)
# Draw the image
imshow(data)

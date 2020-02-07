# Create an image
x = LinRange(-3, 3, 150)
y = LinRange(-2, 2, 100)
# RGB values
r = (1 .+ cos.(atan.(y, x')))/2
g = (1 .+ sin.(atan.(y, x')))/2
b = exp.(-(x'.^2 .+ y.^2)/4)
data = cat(r, g, b, dims=3)
# Draw the image
imshow(data)

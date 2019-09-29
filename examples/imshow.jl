# Create an image
x = LinRange(-3, 3, 150)
y = LinRange(-2, 2, 100)
data = (sin.(exp.(x'.^2 .+ y.^2)) .+ sin.(x') .+ cos.(y) .+ 3) ./ 6
# Draw the image as a color scale
imshow(data)

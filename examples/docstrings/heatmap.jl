# Uniform heatmap on the left
subplot(1,2,1)
x = LinRange(-2, 2, 40)
y = LinRange(0, pi, 20)
z = sin.(x') .+ cos.(y)
heatmap(z)
# Non uniform heatmap on the right
subplot(1,2,2)
x = [0, 2, 3, 4.5, 5]
y = [2, 3, 4.5, 5, 6, 8]
z = rand(5, 4)
heatmap(x, y, z)

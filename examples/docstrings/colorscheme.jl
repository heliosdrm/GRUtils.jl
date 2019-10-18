# Create example data
x = LinRange(0, 3, 20)
y = [sin.(x) exp.(-x)]
# Set a new color scheme and plot the data
subplot(1,2,1)
colorscheme("light")
plot(x, y)
# Make a second plot with a particular scheme
subplot(1,2,2)
plot(x, y, scheme=3) # solarized light
# Now change the global scheme and redraw
# (this only affects the first plot)
colorscheme("solarized dark")
draw(gcf())

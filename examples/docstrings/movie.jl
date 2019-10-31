# Make a plot with example data
x = LinRange(0, 800, 100)
y = sind.(x)
plot(x,y)
# Make a movie sliding over the X axis
movie("webm") do
  for d = 0:10:440
    xlim(d, d+360)
    draw(gcf())
  end
end

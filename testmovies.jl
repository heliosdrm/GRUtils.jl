using GR
# Prepare data
x = LinRange(0, 800, 100)
y = sind.(x)
plot(x,y)
GR.inline("mov")
for d = 0:10:440
  xlim((d, d+360))
  redraw()
end
movie = GR.show();
GR.inline("svg")

write("movietest.html", movie.s)

# Animations and movies

A sequence of figures can be presented as a movie, using the function [`movie`](@ref) -- or [`savemovie`](@ref) in order to save it as a file.

There are two ways of producing plot animations. The sequence of figures may be stored in an array. For instance, a movie that shows a sliding window of the sin function may be created from a collection of figures created like this:

```julia
figures = Figure[]
for d = 0:10:440
  x = LinRange(d, d+360, 45)
  y = sind.(x)
  push!(figures, plot(x, y))
end
```

The array `figures` might be then used to produce a movie in WebM format as follows:

```julia
movie(figures, "webm")         # As a Julia object
savemovie(figures, "sin.webm") # Written in a file
```

The first line of this example creates a movie that can be properly displayed if the code is being executed in an environment that supports such kind of content, like IJulia notebooks or other HTML contexts. Otherwise, it may be more convenient to save the animation in a movie file, as in the second line of the example. Besides `"webm"`, other supported extensions for movies are `"mp4"` and `"mov"`.

However, storing the figures in an array may consume a lot of memory. So, unless you need to keep the figures for some other reason, it is more efficient to use a function that overwrites the previous figure after drawing it. For instance:

```julia
function sliding_window()
  # Make a plot with the full window
  x = LinRange(0, 800, 100)
  y = sind.(x)
  plot(x,y)
  # Draw the sliding window over the X axis
  for d = 0:10:440
    xlim(d, d+360)
    draw(gcf())
  end
end

# Now create the movie with that function
savemovie(sliding_window, "sin.webm")
# or
movie(sliding_window, "webm")
```

The key in that function is the loop with repeated calls to `draw(gcf())`. That command is the one that actually produces the graphic representation of the current figure, i.e. draws each frame of the movie. When making animations, it is not sufficient to call the function `plot` that creates the figures; it is necessary to `draw` them explicitly.

Another convenient way of calling the "function-" versions of `savemovie` or `movie` is with the `do` syntax that lets you create anonymous functions "on the fly", and pass them silently as the first argument of a function. For instance, the following code produces the animation that is shown next:

```@example plot
using GRUtils # hide
Figure(); # hide
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
```

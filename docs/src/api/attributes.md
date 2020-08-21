```@setup attr
using GRUtils, Random
Random.seed!(111)
```
# Plot attributes

The following functions can be used to modify existing plots, adding titles and other textual guides, changing their dimensions, colors, etc.

The majority of those attributes can also be defined at the time of the creation of the plot, adding a keyword argument with the name of the corresponding function and the value of its argument, e.g. `plot(x, y, grid=false)`. That option is commented in the descriptions of the functions that support it.

!!! tip "Texts with LaTeX expressions"

    Attributes with text like titles, axis guides and legends accept strings with UTF-8 characters and LaTeX expressions. The package [LaTeXStrings](https://github.com/stevengj/LaTeXStrings.jl/) can be used to reduce the burden of writing escape sequences in LaTeX expressions.


## Titles
```@docs
title
```
## Axis guides
```@docs
grid
xlabel
xticks
xticklabels
```
## Axis dimensions
```@docs
xlim
aspectratio
zoom
panzoom
```
## 3-D views
```@docs
viewpoint
rotate
tilt
movefocus
turncamera
```
## Axis scales
```@docs
xflip
xlog
radians
```
## Geometry guides
```@docs
legend
geometrykinds
colorbar
```

## Colors
```@docs
background
background!
colormap
```
```@example attr
Figure(); # hide
Base.include(GRUtils, "../examples/docstrings/colormap.jl") # hide
```
```@docs
colormap!
colorscheme
```
```@example attr
Figure((600,250)); # hide
Base.include(GRUtils, "../examples/docstrings/colorscheme.jl") # hide
```
```@docs
colorscheme!
```
```@example attr
colormap("viridis") # hide
colorscheme("none") # hide
```

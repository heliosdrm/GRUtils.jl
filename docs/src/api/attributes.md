# Plot attributes

The following functions can be used to modify existing plots, adding titles and other textual guides, changing their dimensions, etc.

The majority of those attributes can also be defined at the time of the creation of the plot, adding a keyword argument with the name of the corresponding function and the value of its argument, e.g. `plot(x, y, grid=false)`. That option is commented in the descriptions of the functions that support it.

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
## Axis scales
```@docs
xflip
xlog
radians
```
## Geometry guides
```@docs
legend
colorbar
```

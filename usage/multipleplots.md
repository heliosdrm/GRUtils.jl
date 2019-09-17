---
layout: default
title: Working with multiple plots
---
# Working with multiple plots

## Figures

The data generated in the creation of plots are stored in objects of the type `Figure`. There is a global "current figure" which is silently used by all the basic functions to create, modify and save plots. The current figure can be retrieved with the function `gcf()` &mdash; standing for "get current figure". New figures can be created as:

```julia
Figure([figsize, units])
```

where `figsize` is a 2-tuple with the target width and height of the figure, and `units` a string with the abbreviation of the units in which those dimensions are given ("px" for pixels, "in" for inches, "cm" for centimeters or "m" for meters are allowed). The default dimensions used by `Figure()` with no arguments is 600×450 pixels &mdash; or a proportional increased size if the detected display resolution is high. That constructor also sets the "current figure" to the one that has just been created.

As all Julia objects, figures can be assigned to variables, which is useful to work with different figures. Most functions to work with plots in GRUtils have methods or variants that allow to specifiy what figure will be used.

All plotting functions (e.g. `plot`, `scatter`, `histogram`, etc.) have "in-place" versions whose name end with an exclamation mark (i.e. `plot!`, `scatter!`, `histogram!`...), whose first argument can be the `Figure` object where the plot will be created. For instance:

```julia
plot(x, y)       # creates a plot in the current figure
plot!(fig, x, y) # creates the same plot in the figure referred to by `fig`
```

To save a particular figure in an image file, give the variable that contains the figure as second argument to the function `savefig`, i.e. `savefig(filename, fig)`.

Some programming environments may provide only one graphic device, but you can still work with various figures at the same time, although only one can be seen at the same time. To show again a figure that might have been replaced by another on the display, you can use the function `draw`:

```julia
draw(fig) # `fìg` is a figure with a plot to be shown
```

The `draw` function also comes in handy to update the visualization of a figure that might have been modified after its creation.

## Subplots

A figure can contain one or various plots, arranged in a flexible layout. The individual plots are stored in objects of the type `PlotObject`; all the plots of a figure referred to by the variable `fig` are collected in the array `fig.plots`. Normally, plotting operations are applied to the last "subplot", which can be retrieved by the function `currentplot(::Figure)`. Without arguments, that function returns the current plot of the current figure.

The function [`subplot`](https://gr-framework.org/julia-jlgr.html#subplot-80646fe0e2182d636e0875c87ff872c2) can be used to split the current figure into a grid of plots, and define a "subplot" that covers one or more cells of that grid. The syntax of that function is:

```julia
subplot(num_rows, num_cols, indices[, replace])
```

The arguments `num_rows` and `num_cols` indicate the number of rows and columns of the grid of plots into which the figure is meant to be divided, and `indices` is an integer or an array of integers that identify a group of cells in that grid (in row-wise order). This function creates a plot with the minimum size that spans over all those cells, and appends it to the array of plots of the figure, such that it becomes its current plot.

If the viewport of the new subplot coincides with the viewport of an existing one, by default the older one is moved to the first plane, and taken as the "current plot"; but if there is only a partial overlap between the new subplot and other plots, the older ones are removed. To override this behavior and keep all previous plots without changes, set the optional argument `replace` to `false`. For instance:

```julia
# This creates a plot that covers two thirds of the width and height
# of the figure, in the top left corner:
subplot(3, 3, (1, 5))
# This adds a plot that covers the top third part of the figure,
# over the previous one:
subplot(3, 1, 1, false)
# This adds a plot covering the right third part of the figure,
# erasing the previous one:
subplot(1, 3, 3)
```

Subplots can be created for specific figures with the "in-place" function `subplot!`, which differs from `subplot` in that it takes the figure as first argument.

The functions that set the [plot attributes](https://gr-framework.org/julia-jlgr.html#attribute-functions) also have in-place versions (e.g. `title!`, `legend!`, etc.), whose first argument is the figure or the specific plot whose attributes are meant to be modified. For instance:

```julia
leftplot = subplot(1,2,1)
plot(x, y)     # Line plot on the left hand side
rightplot = subplot(1,2,2)
scatter(x, z)  # Scatter plot to the right hand side

fig = gcf()
title!(fig, "Nice plot")         # Same as `title("Nice plot")`
title!(rightplot, "First plot")  # Set the title of the first plot
draw(fig)   # The function `title!` does not update the visualization
```


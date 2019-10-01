```@setup plot
using GRUtils, Random
Random.seed!(111)
```
# Working with multiple plots

## Figures

GRUtils stores the data generated in the creation of plots in objects of the type `Figure`. There is a global "current figure" that is silently used by all the basic functions to create, modify and save plots. The current figure can be retrieved with the function `gcf()` &mdash; standing for "get current figure". New figures can be created with the [`Figure`](@ref) constructor, which in its simplest form is just a call to `Figure()`.

As all Julia objects, figures can be assigned to variables, a useful resource to work with different figures. Most functions to work with plots in GRUtils have methods or variants that allow to specifiy what figure will be used.

All plotting functions (e.g. `plot`, `scatter`, `histogram`, etc.) have "in-place" versions whose name end with an exclamation mark (i.e. `plot!`, `scatter!`, `histogram!`...). The first argument of those functions is the `Figure` object where the plot will be created. For instance:

```julia
plot(x, y)       # creates a plot in the current figure
plot!(fig, x, y) # creates the same plot in the figure referred to by `fig`
```

To save a particular figure in an image file, give the variable that contains the figure as second argument to the function `savefig`, i.e. `savefig(filename, fig)`.

Some programming environments may provide only one graphic device, but you can still work with various figures, although only one can be seen at the same time. To show again a figure that might have been replaced by another on the display, you can use the function `draw`:

```julia
draw(fig) # `fìg` is a figure with a plot to be shown
```

The `draw` function also comes in handy to update the visualization of a figure that might have been modified after its creation.

## Subplots

A figure can contain one or various plots, arranged in a flexible layout. The individual plots are stored in objects of the type `PlotObject`; all the plots of a figure referred to by the variable `fig` are collected in the array `fig.plots`. Normally, plotting operations are applied to the last "subplot", which can be retrieved by the function `currentplot(::Figure)`. Without arguments, that function returns the current plot of the current figure.

The function [`subplot`](@ref) can be used to split the current figure into a grid of plots, and define a "subplot" that covers one or more cells of that grid.

Subplots can be created for specific figures with the "in-place" function `subplot!`, which differs from `subplot` in that it takes the figure as first argument.

The functions that set the [Plot attributes](@ref) also have in-place versions (e.g. `title!`, `legend!`, etc.), whose first argument is the figure or the specific plot whose attributes are meant to be modified. For instance:

```@example plot
# Example data
x = 1:20
y = randn(20)
z = exp.(y) .+ randn(20)
subplot(1,2,1)
plot(x, y)     # Line plot on the left hand side
subplot(1,2,2)
scatter(y, z)  # Scatter plot to the right hand side

fig = gcf()
title!(fig, "Nice plot")         # Same as `title("Nice plot")`
title!(subplot(1,2,1), "First plot")  # Set the title of the first plot
draw(fig)   # The function `title!` does not update the visualization
```

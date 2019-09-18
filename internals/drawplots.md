---
layout: default
title: Drawing plots
---
## Drawing plots

The function `draw` executes the instructions that create the graphical visualization of a plot and its components. That function has specialized methods for the different types that have been described in the [structure of plots](./structure.md). In a top-down order:

* `draw(::Figure)` sets up the workspace and calls the `draw` method for all the `PlotObject`s  contained in `plots`.
* `draw(::PlotObject)` does the following actions:
    1. Paint the background and set the viewport defined by the `viewport` field.
    2. Call the method `draw` on the plot's `axes`.
    3. Call the method `draw` on each item of `geoms`.
    4. Call `draw` on `legend` it is not an empty legend and `attributes[:location] ≠ 0`.
    5. Call `draw` on `colorbar`if it is not an empty color bar and `attributes[:colorbar] == true`).
    6. Write different labels and decorations in axes, title, etc, as defined in `attributes`.
* `draw(::Axes)` sets the window and the scale defined by the axes ranges and other specifications &mdash; except in the case of polar plots, where the polar coordinates are transformed into the Cartesian coordinates of a square of fixed size, and then draws the axes themselves and their guides.
* `draw(::Geometry)` calls specialized methods for the geometry's `kind`, and returns either `nothing` or a `Vector{Float64}` with the limits of the color scale &mdash; when it is calculated by the drawing operation, e.g. in the case of hexagonal bins.
* Legends are drawn by the method `draw(lg::Legend, geoms, location)`, where `geoms` is a vector with the geometries of the plot, and `location` is an integer code that defines the location of the legend with respect to the main plot area &mdash; as defined in [Matplotlib legends](https://matplotlib.org/3.1.1/api/_as_gen/matplotlib.pyplot.legend.html). The geometries are passed down to the `guide` function, which has specialized methods for the kind of geometries that can be represented in legends.
* Color bars are drawn by the method `draw(cb::Colorbar [, range])`, where the optional `range` is by default `cb.range`, but can be overriden by other values.

Continue reading how [plots are created](./createplots.md).

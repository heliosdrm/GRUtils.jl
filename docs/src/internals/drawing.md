# Drawing plots

The function `draw` executes the instructions that create the graphical visualization of a plot and its components. That function has specialized methods for the different types that have been described in the [Structure of plots](@ref). In a top-down order:

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
* Legends are drawn by the method `draw(lg::Legend, geoms, location)`, where `geoms` is a vector with the geometries of the plot, and `location` is an integer code that defines the location of the legend with respect to the main plot area — as defined in [Matplotlib legends](https://matplotlib.org/3.1.1/api/_as_gen/matplotlib.pyplot.legend.html). The geometries are passed down to the `guide` function, which has specialized methods for the kind of geometries that can be represented in legends.
* Color bars are drawn by the method `draw(cb::Colorbar [, range])`, where the optional `range` is by default `cb.range`, but can be overriden by other values.

The `draw` method can be used on a `Figure` to trigger its graphical representation, but in most situations it is not necessary to call it explicitly. It is called automatically whenever a figure is meant to be shown in an environment that support SVG, PNG or HTML outputs, such as [IJulia](https://github.com/JuliaLang/IJulia.jl) notebooks, web-content generators like [Weave](https://github.com/JunoLab/Weave.jl) or [Documenter](https://github.com/JuliaDocs/Documenter.jl), etc. And there is also a `display` method that dispatches on `Figure`, whose main action is calling the corresponding `draw` method, to display figures in rich multimedia devices.

Thus, one way or another, figures are usually drawn automatically by just invoking them, e.g. if in the last line of a code block you write `gcf()`, the name of a variable containing a figure, or if you call a function like `plot` that returns a `Figure`.

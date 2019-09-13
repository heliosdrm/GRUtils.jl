## Creating plots

At the lowest level, a single plot can be created through the following steps:

1. Define a `Viewport` with the NDC of the boxes where the plot should be drawn.
2. Create one or more `Geometry` objects based on the data that should be plotted and the kind of geometries that will represent them, and collect them in a vector.
3. Create an `Axes` object with suitable dimensions and properties to contain the geometries.
4. Create a `Legend` to display the legends, if suitable.
5. Create a `Colorbar` to represent a guide to color codes, if suitable.
6. Put all the previous components together in a `PlotObject`.
7. Take a `Figure` where the plot should be displayed &mdash; e.g. the current figure through `gcf()`, or create it, and put the newly created `PlotObject` into the `plots` vector of that figure.

GRUtils also provides various constructors of those types and other functions that
make those steps easier, as presented next.

### `Viewport` constructors

```julia
Viewport(subplot, frame::Bool [, ratio::Real, margins])
```

This method makes a `Viewport` for a plot taking the normalized coordinates of the box that contains it (`subplot`, which are normalized with respect to the size of the figure, not the whole device), and a flag (`frame::Bool`) telling whether there should be a frame between the outer and inner boxes. The size of that frame is calculated automatically.

This constructor also accepts two optional arguments: `ratio`, which is the width:height ratio of the inner box, and `margins`, a 4-vector with extra margins that there should be between the outer and inner boxes, in addition to the default size of the frame (in the order left-right-bottom-top).

### `Geometry` constructors

```julia
Geometry(kind::Symbol [; kwargs...])
```

Most geometries do not need data for all the possible parameters that the `Geometry` type accepts. Thus, to simplify the creation of geometries, an alternative constructor takes the geometry's `kind` as the only positional argument, and the rest of fields are given as keyword arguments (empty by default).

Besides, there is a function `geometries` to directly create a vector of `Geometry` objects from the input data easily, taking advantage of multiple dispatch:

```julia
geometries(kind, x [, y, z, c; kwargs...]) -> Vector{Geometry}
```

The positional arguments of this function are the `kind` of the geometry, and the variables that define the coordinates of the geometries. All the other parameters are given as keyword arguments, just as in the previously described constructor.

This function accepts coordinates defined only by one array of numbers, by two variables ( `x` and `y`, typically for 2-D plots), three (`x`, `y`, `z`) or all four variables (`x`, `y`, `z` and `c`). If there is only one array `x` of real numbers given for the geometry coordinates, they will actually be used as Y coordinates, and X will be defined as a sequence of integers starting at 1. If that array contains complex numbers, the real part
will be taken as X coordinates, and the imaginary part as Y coordinates.

The coordinates can be given as vectors or matrices with the same number of rows. In the latter case, each column of the matrices will be used to define a different `Geometry`. If some coordinates are given as vectors while other are in matrices, vectors will be recycled in all the geometries. E.g. `x` is a vector with `N` numbers and `y` a matrix with `N` rows and `M` columns, the result will be a `N`-vector of geometries `g` such that `g[i]` will be a geometry whose X coordinates are the vector `x`, and whose Y coordinates are the `i`-th column of `y`.

In addition, the last coordinate can be given as a "broadcastable" function that takes the previous coordinates as inputs.

### `Axes` constructors

```julia
Axes(kind::Symbol [; kwargs...])
Axes(kind, geoms::Array{<:Geometry} [; kwargs...])
```

As in the case of `Geometry`, an alternative `Axes` constructor is provided that only requires the `kind` of the axes (`:axes2d`, `:axes3d` or `:axespolar`),
such that all the other parameters are passed as keyword arguments. Null or
empty values are used by default for the parameters that are not given.

Besides, there is another `Axes` constructor that takes the kind of the axes and the vector of geometries that is meant to be plotted inside the axes, in order to calculate the different axis limits, ticks, etc. Keyword arguments are used to modify the default calculations.

### `Legend` constructors

```julia
Legend(geoms [, maxrows])
```

This `Legend` constructor takes the collection of geometries that are meant to be referred to in the legend, and calculates the dimensions of the legend frame such that it can contain guides to all the geometries that have a non-empty `label`.

Optionally, this constructor takes the maximum number of items that should be represented in a column of the legend, and if the number of labelled geometries exceeds that maximum, the legend is sized to contain all needed columns.

### `Colorbar` constructors

```julia
Colorbar(axes::Axes [, colors=256])
```

This `Colorbar` constructor takes the `Axes` object that is used to calculate the different properties of the color bar, depending on the kind of axis and the range of the `c` axis, which is normally meant to contain the variable that is mapped to a color scale. If the `c` axis is not defined in the axes, this constructor will return an empty `Colorbar`.

### Top-level plot constructors

The constructors presented above for the different components of a plot allow to build plots from data using different "grammars". Besides, GRUtils also provide top-level functions for plot creation that imitate the interface provided by `jlgr`.

Since all those functions follow the same basic steps described above, a macro `@plotfunction` is provided to create them from a template. The interface of this macro is:

```julia
@plotfunction(fname, options...)
```

That macro creates two functions, e.g. `@plotfunction plot` creates the following:

* `plot!(f::Figure, args...; kwargs...)`
* `plot(args...; kwargs...)`

The first of those functions (the one whose name ends with an exclamation) edits the figure given as first argument, replacing its last plot by a new one. The second function (the one without exclamation) creates the plot in the current figure. How those functions work depends on the options that are passed after the function name to the macro. Those options are expressed in the fashion of keyword argments, i.e. as
`key = value`, and they can be the following:

* **`geom`**: a `Symbol` with the name of the kind of the `Geometry` that is created.
* **`axes`**: a `Symbol` with the name of the kind of the `Axes` that are created.
* **`plotkind`**: a `Symbol` with the name of the plot kind (only needed as meta-data). If this option is not given, the name of the function is used by default.
* **`setargs`**: a function that takes the positional and keyword arguments that are passed to the functions, and transforms and extends them to return: (a) a tuple of positional arguments to be passed to the function `geometries`, and (b) the set of keyword arguments that are passed to the constructor of geometries, axes, and the plot object. If `setargs` is not defined, the positional and keyword arguments are returned untransformed.
* **`kwargs`**: a named tuple with extra keyword arguments that are passed to the constructors of geometries, axes and the plot object.
* **`docstring`**: the documentation string that will be assigned to those functions.

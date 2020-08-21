```@meta
CurrentModule = GRUtils
```
# Creating plots

At the lowest level, a single plot can be created through the following steps:

1. Define a `Viewport` with the NDC of the boxes where the plot should be drawn.
2. Create one or more `Geometry` objects based on the data that should be plotted and the kind of geometries that will represent them, and collect them in a vector.
3. Create an `Axes` object with suitable dimensions and properties to contain the geometries.
4. Create a `Legend` to display the legends, if suitable.
5. Create a `Colorbar` to represent a guide to color codes, if suitable.
6. Put all the previous components together in a `PlotObject`.
7. Take a `Figure` where the plot should be displayed —; e.g. the current figure through `gcf()`, or create it, and put the newly created `PlotObject` into the `plots` vector of that figure.

GRUtils also provides various constructors of those types and other functions that make those steps easier.

## `Viewport` constructors

```@docs
Viewport(::Any, ::Bool)
```

## `Geometry` constructors

```@docs
Geometry(::Symbol)
Geometry(::Geometry)
```

There is also a function `geometries` to create vectors of `Geometry` objects from the input data easily, or to fetch them from an already existing plot, taking advantage of multiple dispatch:

```@docs
geometries
```

## `Axes` constructors

There are two alternative constructors for `Axes` objects: one like the alternative `Geometry` constructor, which is basically a shortcut to define only the non-empty parameters via keyword arguments; and another one that sets the axes up automatically based on the data to be plotted.

```@docs
Axes(::Symbol)
Axes(::Any, ::Array{<:Geometry})
```

## `Legend` constructors

```@docs
Legend(::Array{<:Geometry}, ::Any)
```

## `Colorbar` constructors

```@docs
Colorbar(::Axes)
```

## Top-level plot constructors

The constructors presented above for the different components of a plot allow to build plots from data using different "grammars". Besides, GRUtils also provide top-level [Plotting functions](@ref) that imitate the interface provided by `jlgr`.

Since most of those functions follow the same basic steps described above, a macro `@plotfunction` is provided to create them from a template.

```@docs
@plotfunction
```

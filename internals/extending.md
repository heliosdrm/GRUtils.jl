---
layout: default
title: Extending GRUtils
---
# Extending GRUtils

## Creation of new plotting functions

One of the purposes of GRUtils' structure is to facilitate its extension through new kinds of plots. New functions to create plots based on existing geometries (e.g. through statistical transformation of the data) can be created with the `@plotfunction` macro and a custom function that sets up the data. Histograms are an example of this: they are a special kind of bar plots, where the position and heights of the bars are obtained from binning the input data. Now, the histogram functions are defined though something like this:

```julia
@plotfunction(histogram, geom = :bar, axes = :axes2d, kind = :hist,
setargs = _setargs_hist, docstring = doc_hist)
```

The expressions used in that macro call are:

* `histogram`: the name of the function that will be created.
* `geom = :bar`, to declare that the kind of the histogram geometries will be `:bar`.
* `axes = :axes2d`, to declare that it will be a plot drawn on 2-D axes.
* `kind = :hist`, an arbitrary option that helps to identify the kind of plot that will be made, although this is not currently used.
* `setargs = _setargs_hist`: this is where the magic happens (see below). `_setargs_hist` is the name of a function that makes the transformation of the input data into the coordinates of the bars.
* `docstring = doc_hist`: this is used to define the documentation string that will be associated to the plotting function (in this example contained in the variable `doc_hist`).
* `kwargs` (not used in this example): this should be a named tuple with extra keyword arguments that are passed to the constructors of geometries, axes and the plot object.

The macro `@plotfunction` creates two functions, which in this example are:

* `histogram(args...; kwargs...)`, a function that creates a histogram on the current plot of the current figure.
* `histogram!(fig, args...; kwargs...)`, which creates the histogram on the current plot of the figure given as `fig`.

In the most simple cases, the input passed by the user to the new plotting function may be directly the variables that go straight to the `x`, `y`, etc. parameters of the geometries. But often (as in the case of histograms) it is not. In such case it is necessary to define the function that is identified by the `setargs` parameter in the macro. The signature of such a function must be:

```julia
name_of_the_function(f::Figure, args...; kwargs...)
```

There `args` represents the set of positional arguments, and `kwargs` the keyword arguments that are passed by the user to the functions that are going to be created, and `f` is meant to be the figure where the plot will be placed. This "set-up" function can do whatever is needed with those arguments and the information of the figure, but it must return a tuple with two objects:

1. A tuple with the positional arguments that will be passed to `geometries` to create the geometries of the plot.
2. A named tuple containing keyword arguments needed by the different constructors (see the [corresponding section](./createplots.md) about that) to create the correct geometries, axes, etc.

When the keyword arguments needed by the constructors are not determined by the input arguments, but they have fixed values for that kind of plot, it is more convenient to define them in the `kwargs` expression of the macro, instead of using the "set-up" function. But both approaches are equally valid.


## Creation of new geometries

If the new kind of plot implies the definition of a new kind of geometry, other methods should be created in addition. Let's say that this new geometry is called `mygeom`; then at least the following method should be defined:

```julia
draw(g::Geometry, ::Val{:mygeom})
```

This method should contain the low-level plotting instructions based on the functions of GR to draw the geometries (lines, markers, areas and other elements), using the data contained in `g`. The returned value should be `nothing`, unless the ends of the color scale are not given in the geometry `g`, but calculated by the functions of GR. In such case, this method can return a vector with the minimum and maximum values of the color scale (as `Float64`).

If the new geometry is also meant to have a legend key, the following method of the `guide` function should also be defined:

```julia
guide(Val{:mygeom}, g, x, y)
```

This method should contain the plotting instructions to draw the key associated to the geometry `g`  in the (`x`, `y` coordinates). The dimensions of the key should not go outside a rectangular box centred in `(0.0, 0.0)`, with width equal to `0.06` and height equal to `0.03`, in NDC units.

If the geometry also needs attributes that are not defined for other geometries (normally passed to the plotting function as keyword arguments), their name should also be added to the constant `KEYS_GEOM_ATTRIBUTES` in the first lines of `frontend.jl`.

Take into account that the dictionary of geometry attributes only accepts `Float64` numbers, so they should be coded as numbers. If from the user perspective it is more convenient to define them as other types, the function indicated by `setargs` may be used to transform the user-provided argument into a suitable number. (See `_setargs_stair` for an example of this.)

## Extension of plot attributes

The keyword arguments passed to the plotting functions are used to define particular characteristics of the geometries, axes, legends, colorbars and other elements of the plots. Often those characteristics must be part of the `attributes` parameter contained in the target `PlotObject`, because either:

* They do not correspond to any parameter defined in the structure of other objects (as it is the case of the plot title, for instance).
* They should be inherited by plots that are added to the `PlotObject`, when the `hold` attribute is set as `true`.

Unlike the attributes of geometries, which must be numbers, the attributes of a `PlotObject` are stored in a `Dict{Symbol, Any}`, so any type of variable (numbers, strings, even functions) can be stored there. But the names of those attributes are also controlled by the constant `KEY_PLOT_ATTRIBUTES` defined in the first lines of `frontend.jl`. Therefore, if new attributes are defined for plots, it is important to add their names in that vector. Otherwise they will be ignored.


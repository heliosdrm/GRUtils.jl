[Back to index](./index.md)
[Drawing plots](./)

# Extending GRUtils

One of the purposes of GRUtils' structure is to facilitate its extension through new kinds of plots. New functions to create plots based on existing geometries (e.g. through statistical transformation of the data) can be created with the `@plotfunction` macro and a custom function that sets up the data. Histograms are an example of this: the input of a histogram is a set of values that are binned, such that the histogram itself is a bar plot with the frequencies of the bins. Now, the histogram functions are defined though something like:

```julia
@plotfunction(histogram, geom = :bar, axes = :axes2d, kind = :hist,
setargs = _setargs_hist, docstring = doc_hist)
```

The expressions used in that macro call are:

* `histogram`: the name of the function that will be created.
* `geom = :bar`, to declare that the kind of the histogram geometries will be `:bar`.
* `axes = :axes2d`, to declare that it will be a plot drawn on 2-D axes.
* `kind = :hist`, an arbitrary option that helps to identify the kind of plot that will be made, although this is not currently used.
* `setargs = _setargs_hist`: this is where the magic occurs. `_setargs_hist` is the name of a function that makes the transformation of the input data into the coordinates of the bars.
* `docstring = doc_hist`: this is used to define the documentation string that will be associated both to `histogram` and `histogram!` (in this example contained in the variable `doc_hist`).

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

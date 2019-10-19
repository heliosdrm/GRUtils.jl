## Select keyword arguments from lists
const KEYS_GEOM_ATTRIBUTES = [:accelerate, :algorithm, :alpha, :baseline, :clabels, :fillcolor, :horizontal, :label, :linecolor, :linewidth, :markercolor, :markersize, :shadelines, :spec, :skincolor, :stair_position, :xform]
const KEYS_PLOT_ATTRIBUTES = [:backgroundcolor, :colorbar, :colormap, :location, :hold, :overlay_axes, :radians, :ratio, :scheme, :subplot, :title,
    :xflip, :xlabel, :xlim, :xlog, :xticklabels, :yflip, :ylabel, :ylim, :ylog, :yticklabels, :zflip, :zlabel, :zlim, :zlog]

geom_attributes(; kwargs...) = filter(p -> p.first ∈ KEYS_GEOM_ATTRIBUTES, kwargs)
plot_attributes(; kwargs...) = filter(p -> p.first ∈ KEYS_PLOT_ATTRIBUTES, kwargs)

_setargs_default(f, args...; kwargs...) = (args, kwargs)

"""
    @plotfunction(fname, options...)

Macro to create plotting functions. E.g. `@plotfunction plot` creates two
functions:

    * `plot!(f::Figure, args...; kwargs...)`
    * `plot(args...; kwargs...)`

The first of those functions (the one whose name ends with an exclamation)
edits the figure given as first argument, replacing its last plot by a new
one. The second function (the one without exclamation) creates the plot in the
current figure. How those functions work depends on the options that are passed
after the function name to the macro. Those options are expressed in the fashion
of keyword argments, i.e. as `key = value`, and they can be the following:

* **`geom`**: a `Symbol` with the name of the kind of the `Geometry` that is created.
* **`axes`**: a `Symbol` with the name of the kind of the `Axes` that are created.
* **`plotkind`**: a `Symbol` with the name of the plot kind (only needed as meta-data).
    If this option is not given, the name of the function is used by default.
* **`setargs`**: a function that takes the positional and keyword arguments that are
    passed to the functions, and returns: (a) a tuple of positional arguments
    to be passed to the function [`geometries`](@ref)), and
    (b) the set of keyword arguments that are passed to the constructor of
    geometries, axes, and the plot object. If `setargs` is not defined, the
    positional and keyword arguments are returned untransformed.
* **`kwargs`**: a named tuple with extra keyword arguments that are passed to
    the constructors of geometries, axes and the plot object.
* **`docstring`**: the documentation string that will be assigned to the plotting function.
"""
macro plotfunction(fname, options...)
    # Parse options - minimum geom and axes
    dict_op = Dict{Symbol, Any}()
    for op in options
        if typeof(op) <: Expr && op.head ∈ (:(=), :kw)
            dict_op[op.args[1]] = op.args[2]
        end
    end
    if !haskey(dict_op, :geom)
        throw(ArgumentError("`geom` not specified"))
    end
    if !haskey(dict_op, :axes)
        throw(ArgumentError("`axes` not specified"))
    end
    # Define functions
    geom_k = dict_op[:geom]
    axes_k = dict_op[:axes]
    setargs_fun = get(dict_op, :setargs, _setargs_default)
    plotkind = get(dict_op, :kind, Symbol(fname))
    def_kwargs = get(dict_op, :kwargs, NamedTuple())
    fname! = Symbol(fname, :!)
    expr = quote
        function $(fname!)(f::GRUtils.Figure, args...; kwargs...)
            kwargs = (; $(def_kwargs)..., kwargs...)
            p = GRUtils.currentplot(f)
            if haskey(kwargs, :hold)
                holdstate = kwargs[:hold]
            else
                holdstate = get(p.attributes, :hold, false)
            end
            if holdstate
                # Keep all attributes
                kwargs = (; p.attributes..., kwargs...)
                args, kwargs = $setargs_fun(f, args...; kwargs...)
                geoms = [p.geoms; GRUtils.geometries(Symbol($geom_k), args...; GRUtils.geom_attributes(;kwargs...)...)]
            else
                # Only keep previous subplot
                kwargs = (subplot = p.attributes[:subplot], kwargs...)
                args, kwargs = $setargs_fun(f, args...; kwargs...)
                geoms = GRUtils.geometries(Symbol($geom_k), args...; GRUtils.geom_attributes(;kwargs...)...)
            end
            axes = GRUtils.Axes(Symbol($axes_k), geoms; kwargs...)
            GRUtils.makeplot!(f.plots[end], axes, geoms; kind=$plotkind, GRUtils.plot_attributes(; kwargs...)...)
            GRUtils.draw(f)
        end
        $fname(args...; kwargs...) = $fname!(GRUtils.gcf(), args...; kwargs...)
    end
    # Add docstrings if available
    if haskey(dict_op, :docstring)
        push!(expr.args, quote @doc $(dict_op[:docstring]) $fname end)
    end
    esc(expr)
end

function _setargs_line(f, args...; kwargs...)
    if typeof(args[end]) <: AbstractString
        kwargs = (spec=args[end], kwargs...)
        args = args[1:end-1]
    end
    return (args, kwargs)
end

@plotfunction(plot, geom = :line, axes = :axes2d, setargs=_setargs_line, kind = :line, docstring="""
    plot(x[, y, spec; kwargs...])
    plot(x1, y1, x2, y2...; kwargs...)
    plot(x1, y1, spec1...; kwargs...)

Draw one or more line plots.

Lines are defined by the `x` and `y` coordinates of the connected points, given as
numeric vectors, and optionally the format string `spec` that defines the line
and marker style and color as in
[matplotlib](https://matplotlib.org/3.1.1/api/_as_gen/matplotlib.pyplot.plot.html).

The `y` vector can be replaced by a callable that defines the Y coordinates as a
function of the X coordinates.

Multiple lines can be defined by pairs of `x` and `y` coordinates (and optionally
their format strings), passed sequentially as arguments of `plot`.
Alternatively, if various lines have the same X coordinates, their Y values can
be grouped as columns in a matrix.

If no `spec` is given, the series will be plotted as solid lines with a
predefined sequence of colors.

Additionally, specifications of lines and markers can be defined by keyword arguments:

* `linewidth`: line width scale factor.
* `markersize`: marker size scale factor.
* `linecolor`: hexadecimal RGB color code for the line.
* `markercolor`: hexadecimal RGB color code for the markers.

This function can receive a single numeric vector or matrix, which will be
interpreted as the Y coordinates; in such case the X coordinates will be a
sequence of integers starting at 1.

# Examples

```julia
$(_example("plot"))
```
""")

function _setargs_stair(f, args...; kwargs...)
    stair_position_str = get(kwargs, :where, "mid")
    if stair_position_str == "mid"
        stair_position = 0.0
    elseif stair_position_str == "post"
        stair_position = 1.0
    elseif stair_position_str == "pre"
        stair_position = -1.0
    else
        throw(ArgumentError("""`where` must be one of `"mid"`, `"pre"` or `"post"`"""))
    end
    return _setargs_line(f, args...; stair_position=stair_position, kwargs...)
end

@plotfunction(stair, geom = :stair, axes = :axes2d, setargs=_setargs_stair, docstring="""
    stair(x[, y, spec; kwargs...])
    stair(x1, y1, x2, y2...; kwargs...)
    stair(x1, y1, spec1...; kwargs...)

Draw one or more staircase or step plots.

The coordinates and format of the stair outlines are defined as for line plots
(cf. [`plot`](@ref)).

Additionally, the keyword argument `where` can be used to define where the "stairs"
(vertical discontinuities between Y values) shoud be placed:

* `where = "pre"` to make the steps stop at each point (`x[i]`, `y[i]`),
    starting at the previous `x` coordinate except for the first point.
* `where = "post"` to make the steps start at each point (`x[i]`, `y[i]`),
    stopping at the next `x` coordinate except for the last point.
* `where = "mid"` (default) to make the steps go through each point (`x[i]`, `y[i]`)
    starting and ending in the middle of the surrounding x-intervals,
    except for the first and last points.

# Examples

```julia
$(_example("stair"))
```
""")

function _setargs_stem(f, args...; baseline=0.0, kwargs...)
    args, kwargs = _setargs_line(f, args...; kwargs...)
    x = collect(args[1])
    y = collect(args[2])
    args = args[3:end]
    prepend!(x, [minimum(x), maximum(x)])
    prepend!(y, float.([baseline, baseline]))
    return ((x, y, args...), kwargs)
end

@plotfunction(stem, geom = :stem, axes = :axes2d, setargs=_setargs_stem, docstring="""
    stem(x[, y, spec; kwargs...])
    stem(x1, y1, x2, y2...; kwargs...)
    stem(x1, y1, spec1...; kwargs...)

Draw a stem plot

The coordinates and format of the stems and markers are defined as for line plots
(cf. [`plot`](@ref)).

Additionally, the keyword argument `baseline` can be used to define the
Y coordinate where stems should start from.

# Examples

```julia
$(_example("stem"))
```
""")

function _setargs_errorbar(f, x, y, args...; kwargs...)
    # Define bar size
    if length(args) == 0
        throw(ArgumentError("errorbar sizes not defined"))
    else
        low = args[1]
        high = (length(args)==1) ? low : args[2]
    end
    if length(low) == 1
        low = repeat(low, length(x))
    end
    if length(high) == 1
        high = repeat(high, lenght(x))
    end
    # Cap width
    horizontal = get(kwargs, :horizontal, false)
    if haskey(kwargs, :capwidth)
        w = kwargs[:capwidth]/2
    elseif horizontal
        w = 0.015 * (maximum(y) - minimum(y))
    else
        w = 0.015 * (maximum(x) - minimum(x))
    end
    # Coordinates
    if horizontal
        x3 = (x' .+ [-vec(low)'; zeros(1, length(x)); vec(high)'])[:]
        y3 = (y' .+ [-w; 0.0; w])[:]
    else
        x3 = (x' .+ [-w; 0.0; w])[:]
        y3 = (y' .+ [-vec(low)'; zeros(1, length(y)); vec(high)'])[:]
    end
    if typeof(args[end]) <: AbstractString
        kwargs = (; spec=args[end], kwargs...)
    end
    return ((x3, y3), kwargs)
end

@plotfunction(errorbar, geom = :errorbar, axes = :axes2d, setargs=_setargs_errorbar, docstring="""
    errorbar(x, y, err[, spec; kwargs...])
    errorbar(x, y, errlow, errhigh[, spec; kwargs...])

Draw a series of error bars.

Error bars are defined by their `x` and `y` coordinates, and the size of the
error bars at either of each `(x, y)` point. For symmetric error bars,
only a vector `err` is required, such that their total size will be `2 .* err`.
For asymmetric error bars, two vectors `errlow` and `errhigh` are required,
such that the size of the error bars will be `errlow .+ errhigh`.

The optional format string `spec` defines the style and color of the lines
of error bars and the markers at `(x, y)`, as in
[matplotlib](https://matplotlib.org/3.1.1/api/_as_gen/matplotlib.pyplot.plot.html).
If no `specs` are given, the error bars will be plotted as solid lines with a
predefined sequence of colors, without markers.

Additionally, the following keyword arguments can be used to modify the aspect
of the error bars:

* `linewidth::Float64`: line width scale factor.
* `markersize::Float64`: marker size scale factor.
* `linecolor`: hexadecimal RGB color code for the line.
* `horizontal::Bool`: set it to `true` to draw horizontal error bars).
* `capwidth`: fixed value of the width of the bar "caps", in units of
    the X axis (or Y axis if `horizontal` is `true`). If it is not given,
    the cap width will be automatically adjusted to 0.3 times the mean
    separation between data points.

# Examples

```julia
$(_example("errorbar"))
```
""")

function _setargs_polar(f, x, y, args...; kwargs...)
    if !get(kwargs, :radians, true)
        x = collect(x) .* (π/180)
    end
    _setargs_line(f, x, y, args...; kwargs...)
end

@plotfunction(polar, geom = :polarline, axes = :polar, setargs=_setargs_polar,
kwargs = (ratio=1.0,), docstring="""
    polar(angle, radius[, spec; kwargs...])

Draw one or more polar plots.

The first coordinate the represents the angle, and the second the
radius of the line points. The rest is defined as for line plots,
except that the first variable (`angle`) is always required.
(cf. [`plot`](@ref)).

The first variable is by default considered to be radians, and the angular
labels of the grid are shown as factors of π. Use the keyword argument
`radians = false` to pass and show angles in degrees.

!!! note

    Logarithmic and reversed scales ar disabled in polar plots

# Examples

```julia
$(_example("polar"))
```
""")

# Recursive call in case of multiple x-y pairs
for fun = [:plot!, :stair!, :stem!, :polar!]
    @eval function $fun(f::Figure, x, y, u, v, args...; kwargs...)
        holdstate = get(currentplot(f).attributes, :hold, false)
        if typeof(u) <: AbstractString
            $fun(f, x, y, u; kwargs...)
            hold!(currentplot(f), true)
            $fun(f, v, args...; kwargs...)
        else
            $fun(f, x, y; kwargs...)
            hold!(currentplot(f), true)
            $fun(f, u, v, args...; kwargs...)
        end
        hold!(currentplot(f), holdstate)
        draw(f)
    end
end

@plotfunction(scatter, geom = :scatter, axes = :axes2d, kwargs=(colorbar=true,),
docstring="""
    scatter(x[, y, size, color; kwargs...])

Draw a scatter plot.

Points are defined by their `x` and `y` coordinates, given as numeric vectors.
Additionally, values for markers' `size` and `color` can be provided.
Size values will determine the marker size in percent of the regular size,
and color values will be used in combination with the current colormap.

The last variable can be replaced by a callable that defines it as a
function of the previous variables.

This function can receive a single numeric vector or matrix, which will be
interpreted as the Y coordinates; in such case the X coordinates will be a
sequence of integers starting at 1.

# Examples

```julia
$(_example("scatter"))
```
""")

# horizontal and vertical coordinates of bar edges
function barcoordinates(heights; barwidth=0.8, baseline=0.0, kwargs...)
    n = length(heights)
    halfw = barwidth/2
    wc = zeros(2n)
    hc  = zeros(2n)
    for (i, value) in enumerate(heights)
        wc[2i-1] = i - halfw
        wc[2i]   = i + halfw
        hc[2i-1] = baseline
        hc[2i]   = value
    end
    (wc, hc)
end

function _setargs_bar(f, labels, heights; horizontal=false, kwargs...)
    wc, hc = barcoordinates(heights; kwargs...)
    if horizontal
        args = (hc, wc)
        tickoptions = (yticks = (1,1), yticklabels = string.(labels))
    else
        args = (wc, hc)
        tickoptions = (xticks = (1,1), xticklabels = string.(labels))
    end
    return (args, (; tickoptions..., kwargs...))
end

function _setargs_bar(f, heights; kwargs...)
    n = length(heights)
    _setargs_bar(f, string.(1:n), heights; kwargs...)
end

@plotfunction(barplot, geom = :bar, axes = :axes2d, setargs=_setargs_bar, docstring="""
    bar(labels, heights; kwargs...)
    bar(heights; kwargs...)

Draw a bar plot.

If no specific labels are given, the bars are labelled with integer
numbers starting from 1.

Use the keyword arguments `barwidth`, `baseline` or `horizontal`
to modify the aspect of the bars, which by default is:

* `barwidth = 0.8` (80% of the separation between bars).
* `baseline = 0.0` (bars starting at zero).
* `horizontal = false` (vertical bars)

Use also the keyword argument `fillcolor` to set a particular
color for the bars, using an hexadecimal RGB color code.

# Examples

```julia
$(_example("barplot"))
```
""")

# Coordinates of the bars of a histogram of the values in `x`
function hist(x, nbins=0, baseline=0.0)
    if nbins <= 1
        nbins = round(Int, 3.3 * log10(length(x))) + 1
    end

    xmin, xmax = extrema(x)
    edges = range(xmin, stop = xmax, length = nbins + 1)
    counts = zeros(nbins)
    buckets = Int[max(2, min(searchsortedfirst(edges, xᵢ), length(edges)))-1 for xᵢ in x]
    for b in buckets
        counts[b] += 1
    end
    wc = zeros(2nbins)
    hc  = zeros(2nbins)
    for (i, value) in enumerate(counts)
        wc[2i-1] = edges[i]
        wc[2i]   = edges[i+1]
        hc[2i-1] = baseline
        hc[2i]   = value
    end
    (wc, hc)
end

function _setargs_hist(f, x; nbins = 0, horizontal = false, kwargs...)
    # Define baseline - 0.0 by default, unless using log scale
    if get(kwargs, :ylog, false) || horizontal && get(kwargs, :xlog, false)
        baseline = 1.0
    else
        baseline = 0.0
    end
    wc, hc = hist(x, nbins, baseline)
    args = horizontal ? (hc, wc) : (wc, hc)
    return (args, kwargs)
end

@plotfunction(histogram, geom = :bar, axes = :axes2d, kind = :hist, setargs = _setargs_hist,
docstring="""
    histogram(data; kwargs...)

Draw a histogram of `data`.

The following keyword arguments can be supplied:

* `nbins`: Number of bins; by default, or if a number smaller than 1 is given,
    the number of bins is computed as `3.3 * log10(n) + 1`,  with `n` being the
    number of elements in `data`.
* `horizontal`: whether the histogram should be horizontal (`false` by default).
* `fillcolor`: hexadecimal RGB color code for the bars.

!!! note

    If the vertical axis (or the horizontal axis if `horizontal == true`) is set
    in logarithmic scale, the bars of the histogram will start at 1.0.

# Examples

```julia
$(_example("histogram"))
```
""")

function _setargs_polarhist(f, x; kwargs...)
    if get(kwargs, :fullcircle, false)
        minval, maxval = extrema(x)
        x = (collect(x) .- minval) .* (2π / (maxval - minval))
    elseif !get(kwargs, :radians, true)
        x = collect(x) .* π / 180
    end
    _setargs_hist(f, x; kwargs..., horizontal=false)
end

@plotfunction(polarhistogram, geom = :polarbar, axes = :polar, kind = :polarhist,
setargs = _setargs_polarhist, kwargs = (ratio=1.0, overlay_axes=true), docstring="""
    polarhistogram(data; kwargs...)

Draw a polar histogram of angle values contained in `data`.

The following keyword arguments can be supplied:

* `nbins`: Number of bins; by default, or if a number smaller than 1 is given,
    the number of bins is computed as `3.3 * log10(n) + 1`,  with `n` being the
    number of elements in `data`.
* `radians`: Set this argument to `false` to pass and show the angles as degrees.
    By default, `data` is assumed to be radians and the angular labels of the
    grid are presented as factors of π.
* `fullcircle`: Set this argument to `true` to scale the angular coordinates of
    the histogram and make the bars span over the whole circle.
* `fillcolor`: hexadecimal RGB color code for the bars.

!!! note

    Logarithmic and reversed scales ar disabled in polar plots

# Examples

```julia
$(_example("polarhistogram"))
```
""")

@plotfunction(plot3, geom = :line3d, axes = :axes3d, kwargs = (ratio=1.0,), setargs=_setargs_line, docstring="""
    plot3(x, y, z[, spec; kwargs...])
    plot3(x1, y1, z1, x2, y2, z2...; kwargs...)
    plot3(x1, y1, z1, spec1...; kwargs...)

Draw one or more three-dimensional line plots.

Lines are defined by the `x`, `y` and `z` coordinates of the connected points,
given as numeric vectors, and optionally the format string `spec` that defines
the line and marker style and color as in
[matplotlib](https://matplotlib.org/3.1.1/api/_as_gen/matplotlib.pyplot.plot.html).

The `z` vector can be replaced by a callable that defines the Z coordinates as a
function of the X and Y coordinates.

Multiple lines can be defined by triplets of `x`, `y` and `z` coordinates (and
optionally their format strings), passed sequentially as arguments of `plot3`.

If no `specs` are given, the series will be plotted as solid lines with a
predefined sequence of colors.

Additionally, specifications of lines and markers can be defined by keyword arguments:

* `linewidth`: line width scale factor.
* `markersize`: marker size scale factor.
* `linecolor`: hexadecimal RGB color code for the line.
* `markercolor`: hexadecimal RGB color code for the markers.

# Examples

```julia
$(_example("plot3"))
```
""")

function plot3!(f::Figure, x, y, z, u, v, args...; kwargs...)
    holdstate = get(currentplot(f).attributes, :hold, false)
    if typeof(u) <: AbstractString
        plot3!(f, x, y, z, u; kwargs...)
        hold!(currentplot(f), true)
        plot3!(f, v, args...; kwargs...)
    else
        plot3!(f, x, y, z; kwargs...)
        hold!(currentplot(f), true)
        plot3!(f, u, v, args...; kwargs...)
    end
    hold!(currentplot(f), holdstate)
    draw(f)
end

_setargs_scatter3(f, x, y, z; kwargs...) = ((x,y,z), kwargs)
_setargs_scatter3(f, x, y, z, c; kwargs...) = ((x,y,z,c), (;colorbar=true, kwargs...))

@plotfunction(scatter3, geom = :scatter3, axes = :axes3d, setargs = _setargs_scatter3,
kwargs = (ratio=1.0,), docstring="""
    scatter3(x, y, z[, color; kwargs...])

Draw a three-dimensional scatter plot.

Points are defined by their `x`, `y` and `z` coordinates, given as numeric vectors.
Additionally, values for markers' `color` can be provided, which will be used in
combination with the current colormap.

The last variable can be replaced by a callable that defines it as a
function of the previous variables.

# Examples

```julia
$(_example("scatter3"))
```
""")

# Contour arguments for different inputs:
# Coordinates (x, y, z) and countour line levels
function _setargs_contour(f, x, y, z, h; kwargs...)
    if length(x) == length(y) == length(z)
        x, y, z = GR.gridit(vec(x), vec(y), vec(z), 200, 200)
    else
        z = z'
    end
    if get(kwargs, :colorbar, true)
        majorlevels = get(kwargs, :majorlevels, 0)
        clabels = float(1000 + majorlevels)
        kwargs = (; colorbar = true, clabels = clabels, kwargs...)
    else
        majorlevels = get(kwargs, :majorlevels, 1)
        clabels = float(majorlevels)
        kwargs = (; clabels = clabels, kwargs...)
    end
    if majorlevels ≠ 0
        kwargs = (; kwargs..., ratio = 1.0)
    end
    return ((vec(x), vec(y), vec(z), vec(h)), kwargs)
end

# Coordinates (x, y, z) with countor lines automatically calculated
function _setargs_contour(f, x, y, z; levels = 20, kwargs...)
    (x, y, z, _), kwargs = _setargs_contour(f, x, y, z, []; kwargs...)
    levels = Int(levels)
    zmin, zmax = get(kwargs, :zlim, (_min(z), _max(z)))
    hmin, hmax = GR.adjustrange(zmin, zmax)
    h = range(hmin, stop = hmax, length = levels + 1)
    return ((x, y, z, h), kwargs)
end

# z values are calculated from a function
function _setargs_contour(f, x, y, fz::Function, args...; kwargs...)
    z = fz.(transpose(vec(x)), vec(y))
    _setargs_contour(f, x, y, z, args...; kwargs...)
end

@plotfunction(contour, geom = :contour, axes = :axes3d, setargs = _setargs_contour,
kwargs = (rotation=0, tilt=90), docstring="""
    contour(x, y, z; kwargs...)

Draw a contour plot.

The current colormap is used to display a either a series of
points or a two-dimensional array as a contour plot. It can receive one
of the following:

- `x` values, `y` values and `z` values.
- *M* sorted values of the `x` axis, *N* sorted values of the `y` axis,
    and a set of `z` values on a *N*×*M* grid.
- *M* sorted values of the `x` axis, *N* sorted values of the `y` axis,
    and a callable to determine `z` values.

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

Contour lines are colored by default, using the current colormap as color scale.
Colored lines can be disabled by removing the color bar (with keyword argument
`colorbar == false`).

The following keyword arguments can be provided to set the number and aspect of
the contour lines:

* `levels::Int`, the number of contour lines that will be fitted to the data
    (20 by default).
* `majorlevels::Int`, the number of levels between labelled contour lines
    (no labels by default for colored lines, all lines labelled by default
    if color is removed).

# Examples

```julia
$(_example("contour"))
```
""")

@plotfunction(contourf, geom = :contourf, axes = :axes3d, setargs = _setargs_contour,
kwargs = (rotation=0, tilt=90, tickdir=-1), docstring="""
    contourf(x, y, z; kwargs...)

Draw a filled contour plot.

The current colormap is used to display a either a series of
points or a two-dimensional array as a filled contour plot. It can receive one
of the following:

- `x` values, `y` values and `z` values.
- *M* sorted values of the `x` axis, *N* sorted values of the `y` axis,
    and a set of `z` values on a *N*×*M* grid.
- *M* sorted values of the `x` axis, *N* sorted values of the `y` axis,
    and a callable to determine `z` values.

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

The following keyword arguments can be provided to set the number and aspect of
the contour lines:

* `levels::Int`, the number of contour lines that will be fitted to the data
    (20 by default).
* `majorlevels::Int`, the number of levels between labelled contour lines
    (no labels by default).

# Examples

```julia
$(_example("contourf"))
```
""")

_setargs_tricont(f, x, y, z, h; kwargs...) = ((x, y, z, h), kwargs...)

function _setargs_tricont(f, x, y, z; levels = 20, kwargs...)
    levels = Int(levels)
    zmin, zmax = get(kwargs, :zlim, (_min(z), _max(z)))
    hmin, hmax = GR.adjustrange(zmin, zmax)
    h = range(hmin, stop = hmax, length = levels)
    return ((x, y, z, h), kwargs)
end

function _setargs_tricont(f, x, y, fz::Function, args...; kwargs...)
    z = fz.(transpose(vec(x)), vec(y))
    _setargs_tricont(f, x, y, z, args...; kwargs...)
end

@plotfunction(tricont, geom = :tricont, axes = :axes3d, setargs = _setargs_tricont,
kwargs = (colorbar=true, rotation=0, tilt=90), docstring="""
    tricont(x, y, z; kwargs...)

Draw a triangular contour plot.

The current colormap is used to display a series of points
as a triangular contour plot. `z` values are interpolated between `x` and `y`
values through [Delaunay triangulation](http://mathworld.wolfram.com/DelaunayTriangulation.html).

The number of contour lines can be set by the keyword argument `levels`
(by default `levels = 20`).

!!! note

    If the series of points is concave, there may be interpolation artifacts on
    the edges of the plot, as the interpolation may occur in very acute triangles.

# Examples

```julia
$(_example("tricont"))
```
""")

function _setargs_surface(f, x, y, z; accelerate = true, kwargs...)
    if length(x) == length(y) == length(z)
        x, y, z = GR.gridit(vec(x), vec(y), vec(z), 200, 200)
    else
        z = z'
    end
    accelerate = Bool(accelerate) ? 1.0 : 0.0
    ((vec(x), vec(y), vec(z), vec(z)), (; accelerate = accelerate, kwargs...))
end

# z values are calculated from a function
function _setargs_surface(f, x, y, fz::Function, args...; kwargs...)
    z = fz.(transpose(vec(x)), vec(y))
    _setargs_surface(f, x, y, z, args...; kwargs...)
end

@plotfunction(surface, geom = :surface, axes = :axes3d, setargs = _setargs_surface,
kwargs = (colorbar=true, accelerate=true), docstring="""
    surface(x, y, z; kwargs...)

Draw a three-dimensional surface plot.

Either a series of points or a two-dimensional array is drawn as
a surface plot, colored according to the Z coordinates and the
current colormap. It can receive one of the following:

- `x` values, `y` values and `z` values.
- *M* sorted values of the `x` axis, *N* sorted values of the `y` axis,
    and a set of `z` values on a *N*×*M* grid.
- *M* sorted values of the `x` axis, *N* sorted values of the `y` axis,
    and a callable to determine `z` values.

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

# Examples

```julia
$(_example("surface"))
```
""")

@plotfunction(wireframe, geom = :wireframe, axes = :axes3d, setargs = _setargs_surface, docstring="""
    wireframe(x, y, z; kwargs...)

Draw a three-dimensional wireframe plot.

Either a series of points or a two-dimensional array is drawn as
a wireframe plot. It can receive one of the following:

- `x` values, `y` values and `z` values.
- *M* sorted values of the `x` axis, *N* sorted values of the `y` axis,
    and a set of `z` values on a *N*×*M* grid.
- *M* sorted values of the `x` axis, *N* sorted values of the `y` axis,
    and a callable to determine `z` values.

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

# Examples

```julia
$(_example("wireframe"))
```
""")

@plotfunction(trisurf, geom = :trisurf, axes = :axes3d, setargs = _setargs_tricont,
kwargs = (colorbar=true,), docstring="""
    tricont(x, y, z; kwargs...)

Draw a triangular surface plot.

Either a series of points or a two-dimensional array is drawn as a
triangular surface plot. `z` values are interpolated between `x` and `y`
values through [Delaunay triangulation](http://mathworld.wolfram.com/DelaunayTriangulation.html).

!!! note

    If the series of points is concave, there may be interpolation artifacts on
    the edges of the plot, as the interpolation may occur in very acute triangles.

# Examples

```julia
$(_example("tricont"))
```
""")

function _setargs_heatmap(f, data; kwargs...)
    h, w = size(data)
    if get(kwargs, :xflip, false)
        data = reverse(data, dims=1)
    end
    if get(kwargs, :yflip, false)
        data = reverse(data, dims=2)
    end
    kwargs = (; xlim = (0.0, float(w)), ylim = (0.0, float(h)), kwargs...)
    ((1.0:w, 1.0:h, emptyvector(Float64), vec(data')), kwargs)
end

@plotfunction(heatmap, geom = :heatmap, axes = :axes2d, setargs = _setargs_heatmap,
kwargs = (colorbar=true, tickdir=-1), docstring="""
    heatmap(data; kwargs...)

Draw a heatmap.

The current colormap is used to display a two-dimensional array `data` as a heatmap.

If `data` is an *N*×*M* array, the cells of the heatmap will be plotted in
an uniform grid of square cells,spanning the interval `[1, M+1]` in the X-axis,
and `[1, N+1]` in the Y-axis.
The array is drawn with its first value in the bottom left corner, so in some
cases it may be neccessary to flip the columns.

By default column and row indices are used for the x- and
y-axes, respectively, so setting the axis limits is recommended. Also note that the
values in the array must lie within the current z-axis limits so it may
be neccessary to adjust these limits or clip the range of array values.

# Examples

```julia
$(_example("heatmap"))
```
""")

@plotfunction(polarheatmap, geom = :polarheatmap, axes = :polar, setargs = _setargs_heatmap, kwargs = (colorbar=true, overlay_axes=true, ratio=1.0))

_setargs_hexbin(f, x, y; kwargs...) = ((x, y, emptyvector(Float64), [0.0, 1.0]), kwargs)

@plotfunction(hexbin, geom = :hexbin, axes = :axes2d, setargs = _setargs_hexbin,
kwargs = (colorbar=true, nbins=40), docstring="""
    hexbin(x, y; kwargs...)

Draw a hexagon binning plot.

Hexagonal binning and the the current colormap are used to display a bi-dimensional
series of points given by `x` and `y`.
The number of bins is 40 by default; use the keyword argument `nbins` to set
it as a different number.

# Examples

```julia
$(_example("hexbin"))
```
""")

function _setargs_imshow(f, data; kwargs...)
    if isa(data, AbstractString)
        w, h, rgbdata = GR.readimage(data)
    else
        h, w = size(data)
        GR.setcolormap(get(kwargs, :colormap, COLOR_INDICES[:colormap]))
        rgbdata = [to_rgba(value) for value ∈ transpose(data)]
    end
    if get(kwargs, :xflip, false)
        rgbdata = reverse(rgbdata, dims=2)
    end
    if get(kwargs, :yflip, false)
        rgbdata = reverse(rgbdata, dims=1)
    end
    kwargs = (; xlim = (0.0, float(w)), ylim = (0.0, float(h)), ratio = w/h, kwargs...)
    ((1.0:w, 1.0:h, emptyvector(Float64), float.(rgbdata[:])), kwargs)
end

@plotfunction(imshow, geom = :image, axes = :axes2d, setargs = _setargs_imshow,
kwargs = (xticks=NULLPAIR, yticks=NULLPAIR, noframe=true), docstring="""
    imshow(img; kwargs...)

Draw an image.

The input `img` can be either a string with a valid file name of an image,
or a matrix of values between 0 and 1, which will be drawn with a hue
corresponding to the relative position of each value in the current colormap.

# Examples

```julia
$(_example("imshow"))
```
""")

function _setargs_isosurf(f, v, isovalue; kwargs...)
    values = round.((v .- _min(v)) ./ (_max(v) .- _min(v)) .* (2^16-1))
    dimensions = float.(collect(size(v)))
    isoval_norm = (isovalue - _min(v)) / (_max(v) - _min(v))
    # x = dimensions, y = isovalue, z = values, c = color
    ((dimensions, [isoval_norm], values[:]), kwargs)
end

@plotfunction(isosurface, geom = :isosurf, axes = :axes3d, setargs = _setargs_isosurf,
kwargs = (xticks=NULLPAIR, yticks=NULLPAIR, zticks=NULLPAIR, ratio=1.0, gr3=true), docstring="""
    isosurface(data, isovalue; kwargs...)

Draw an isosurface determined by the region of the three-dimensional array `data`
around a given `isovalue`.

The isosurface is calculated so that values in `data` greater than `isovalue` are
considered to be outside the surface, and the values lower than `isovalue` are
inside the surface.

The color of the isosurface can be chosen with the keyword argument
`skincolor`, with the hexadecimal RGB color code.

# Examples

```julia
$(_example("isosurface"))
```
""")

const XFORMS = Dict(
    "boolean"=>0, "linear"=>1, "log"=>2,
    "loglog"=>3, "cubic"=>4, "equalized"=>5
)

function _setargs_shade(f, x, y; kwargs...)
    # Determine type of footprint
    default_footprint = hasnan(x) || hasnan(y) ? "lines" : "points"
    footprint = get(kwargs, :footprint, default_footprint)
    if footprint == "lines"
        kwargs = (; shadelines = 1.0, kwargs...)
    elseif footprint == "points"
        kwargs = (; shadelines = 0.0, kwargs...)
    else
        throw(ArgumentError("""`footprint` must be either `"lines"` or `"points"`"""))
    end
    # Transformation
    if haskey(kwargs, :xform)
        xf = lookup(kwargs[:xform], XFORMS)
        kwargs = (; kwargs..., xform=float(xf))
    end
    return ((x, y), kwargs)
end

@plotfunction(shade, geom = :shade, axes = :axes2d, kwargs = (tickdir=-1,),
setargs = _setargs_shade, docstring="""
    shade(x, y; kwargs...)

Draw a point- or line-based heatmap.

The current colormap is used to display the footprint left by the pairs of
`x`, `y` values. If the data contain `NaN` or `missing`, the footprints
will be based on lines separated by those values. Otherwise the footprints
will be based on points. The type of footprint can be enforced regardless
of the input by the keyword argument `footprint = "lines"` or
`footprint = "points"`.

The value of that footprint is determined by a transformation that can be
adjusted by the keyword argument `xform` --- a number or a string from the
following table:

| # |String       |description                  |
|:-:|:------------|:----------------------------|
| 0 |`"boolean"`  |boolean                      |
| 1 |`"linear"`   |linear                       |
| 2 |`"log"`      |logarithmic                  |
| 3 |`"loglog"`   |double logarithmic           |
| 4 |`"cubic"`    |cubic                        |
| 5 |`"equalized"`|histogram equalized (default)|

# Examples

```julia
$(_example("shade"))
```
""")

const ALGORITHMS = Dict("emission"=>0, "absorption"=>1, "mip"=>2)

function _setargs_volume(f, v::Array{T, 3}; kwargs...) where {T}
    (nx, ny, nz) = size(v)
    # Algorithm
    if haskey(kwargs, :algorithm)
        alg = lookup(kwargs[:algorithm], ALGORITHMS)
        kwargs = (; kwargs..., algorithm=float(alg))
    end
    (([nx], [ny], [nz], vec(v)), kwargs)
end

@plotfunction(volume, geom = :volume, axes = :axes3d, setargs = _setargs_volume,
kwargs = (colorbar=true,), docstring="""
    volume(v; kwargs...)

Draw a the three-dimensional array `v`, using volume rendering.

The volume data is reduced to a two-dimensional image using
an emission or absorption model, or by a maximum intensity projection.
After the projection the current colormap is applied to the result.

The method to reduce volume data can be defined by the keyword argument
`algorithm` --- a number or a string from the
following table:

| # |String        |description                 |
|:-:|:-------------|:---------------------------|
| 0 |`"emission"`  |emission model (default)    |
| 1 |`"absorption"`|absorption model            |
| 2 |`"mip"`       |maximum intensity projection|

# Examples

```julia
$(_example("volume"))
```
""")

function oplot!(f::Figure, args...; kwargs...)
    p = currentplot(f)
    kwargs = (; p.attributes..., kwargs...)
    if typeof(args[end]) <: AbstractString
        kwargs = (spec=args[end], kwargs...)
        args = args[1:end-1]
    end
    append!(p.geoms, geometries(:line, args...; geom_attributes(; kwargs...)...))
    draw(f)
end

"""
    oplot(args...; kwargs...)

Draw one or more line plots over another plot.

Equivalent to calling [`plot`](@ref) after holding the current plot,
except that the axes limits are not re-adjusted to the new data.

# Examples

```julia
$(_example("oplot"))
```
"""
oplot(args...; kwargs...) = oplot!(gcf(), args...; kwargs...)


"""
    savefig(filename[, fig])

Save a figure to a file.

Draw the current figure in a file of the given name.
Which file types are supported depends on the installed workstation types,
but GR usually is built with support for
.png, .jpg, .pdf, .ps, .gif and various other file formats.

If no figure is given (optional argument `fig`), the current figure
is used.

# Examples

```julia
# Create a simple plot
x = 1:100
plot(x, 1 ./ (x .+ 1))
# Save the figure to a file
savefig("example.png")
```
"""
function savefig(filename, fig=gcf())
    GR.beginprint(filename)
    draw(fig)
    GR.endprint()
end

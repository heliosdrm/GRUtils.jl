## Select keyword arguments from lists
const KEYS_GEOM_ATTRIBUTES = [:accelerate, :algorithm, :alpha, :baseline, :clabels, :label, :linewidth, :markersize, :spec, :stair_position, :xform]
const KEYS_PLOT_ATTRIBUTES = [:backgroundcolor, :colorbar, :colormap, :location, :hold, :overlay_axes, :ratio, :scheme, :subplot, :title,
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
            f.plots[end] = GRUtils.PlotObject(axes, geoms; kind=$plotkind, GRUtils.plot_attributes(; kwargs...)...)
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

# Fetch example from filename and return it as String
_example(name) = read(joinpath(dirname(@__FILE__), "../examples", "$name.jl"), String)

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

If no `specs` are given, the series will be plotted as solid lines with a
predefined sequence of colors.

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
(cf. [plot](@ref)).

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

@plotfunction(stem, geom = :stem, axes = :axes2d, setargs=_setargs_line, docstring="""
    stem(x[, y, spec; kwargs...])
    stem(x1, y1, x2, y2...; kwargs...)
    stem(x1, y1, spec1...; kwargs...)

Draw a stem plot

The coordinates and format of the stems and markers are defined as for line plots
(cf. [plot](@ref)).

Additionally, the keyword argument `baseline` can be used to define the
Y coordinate where stems should start from.

# Examples

```julia
$(_example("stem"))
```
""")

# Recursive call in case of multiple x-y pairs
for fun = [:plot!, :stair!, :stem!]
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
Additionally, values for markers' `size` and `color` can be provided
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

# Examples

```julia
$(_example("bar"))
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

!!! note

    If the vertical axis (or the horizontal axis if `horizontal == true`) is set
    in logarithmic scale, the bars of the histogram will start at 1.0.

# Examples

```julia
$(_example("histogram"))
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
optionally their format strings), passed sequentially as arguments of `plot`.
Alternatively, if various lines have the same X and Y coordinates, their Y values can
be grouped as columns in a matrix.

If no `specs` are given, the series will be plotted as solid lines with a
predefined sequence of colors.

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

@plotfunction(polar, geom = :polarline, axes = :polar, setargs=_setargs_line, kwargs = (ratio=1.0,), docstring="""
Draw one or more polar plots.

This function can receive one or more of the following:

- angle values and radius values, or
- angle values and a callable to determine radius values

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> angles = LinRange(0, 2pi, 40)
    julia> radii = LinRange(0, 2, 40)
    julia> # Plot angles and radii
    julia> polar(angles, radii)
    julia> # Plot angles and a callable
    julia> polar(angles, r -> cos(r) ^ 2)
""")

@plotfunction(polarhistogram, geom = :polarbar, axes = :polar, kind = :polarhist,
setargs = _setargs_hist, kwargs = (ratio=1.0,), docstring="""
Draw a polar histogram.

If **nbins** is **Nothing** or 0, this function computes the number of
bins as 3.3 * log10(n) + 1,  with n as the number of elements in x,
otherwise the given number of bins is used for the histogram.

:param x: the values to draw as a polar histogram
:param num_bins: the number of bins in the polar histogram

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = 2 .* rand(100) .- 1
    julia> # Draw the polar histogram
    julia> polarhistogram(x, alpha=0.5)
    julia> # Draw the polar histogram with 19 bins
    julia> polarhistogram(x, nbins=19, alpha=0.5)
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
Draw a contour plot.

This function uses the current colormap to display a either a series of
points or a two-dimensional array as a contour plot. It can receive one
or more of the following:

- x values, y values and z values, or
- M x values, N y values and z values on a NxM grid, or
- M x values, N y values and a callable to determine z values

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) .+ cos.(y)
    julia> # Draw the contour plot
    julia> contour(x, y, z)
    julia> # Create example grid data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw the contour plot
    julia> contour(x, y, z)
    julia> # Draw the contour plot using a callable
    julia> contour(x, y, (x,y) -> sin(x) + cos(y))
""")

@plotfunction(contourf, geom = :contourf, axes = :axes3d, setargs = _setargs_contour,
kwargs = (rotation=0, tilt=90, tickdir=-1), docstring="""
Draw a filled contour plot.

This function uses the current colormap to display a either a series of
points or a two-dimensional array as a filled contour plot. It can
receive one or more of the following:

- x values, y values and z values, or
- M x values, N y values and z values on a NxM grid, or
- M x values, N y values and a callable to determine z values

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) .+ cos.(y)
    julia> # Draw the contour plot
    julia> contourf(x, y, z)
    julia> # Create example grid data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw the contour plot
    julia> contourf(x, y, z)
    julia> # Draw the contour plot using a callable
    julia> contourf(x, y, (x,y) -> sin(x) + cos(y))
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
Draw a triangular contour plot.

This function uses the current colormap to display a series of points
as a triangular contour plot. It will use a Delaunay triangulation to
interpolate the z values between x and y values. If the series of points
is concave, this can lead to interpolation artifacts on the edges of the
plot, as the interpolation may occur in very acute triangles.

:param x: the x coordinates to plot
:param y: the y coordinates to plot
:param z: the z coordinates to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) + cos.(y)
    julia> # Draw the triangular contour plot
    julia> tricont(x, y, z)
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
Draw a three-dimensional surface plot.

This function uses the current colormap to display a either a series of
points or a two-dimensional array as a surface plot. It can receive one or
more of the following:

- x values, y values and z values, or
- M x values, N y values and z values on a NxM grid, or
- M x values, N y values and a callable to determine z values

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) .+ cos.(y)
    julia> # Draw the surface plot
    julia> surface(x, y, z)
    julia> # Create example grid data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw the surface plot
    julia> surface(x, y, z)
    julia> # Draw the surface plot using a callable
    julia> surface(x, y, (x,y) -> sin(x) + cos(y))
""")

@plotfunction(wireframe, geom = :wireframe, axes = :axes3d, setargs = _setargs_surface, docstring="""
Draw a three-dimensional wireframe plot.

This function uses the current colormap to display a either a series of
points or a two-dimensional array as a wireframe plot. It can receive one
or more of the following:

- x values, y values and z values, or
- M x values, N y values and z values on a NxM grid, or
- M x values, N y values and a callable to determine z values

If a series of points is passed to this function, their values will be
interpolated on a grid. For grid points outside the convex hull of the
provided points, a value of 0 will be used.

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) .+ cos.(y)
    julia> # Draw the wireframe plot
    julia> wireframe(x, y, z)
    julia> # Create example grid data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw the wireframe plot
    julia> wireframe(x, y, z)
    julia> # Draw the wireframe plot using a callable
    julia> wireframe(x, y, (x,y) -> sin(x) + cos(y))
""")

@plotfunction(trisurf, geom = :trisurf, axes = :axes3d, setargs = _setargs_tricont,
kwargs = (colorbar=true,), docstring="""
Draw a triangular surface plot.

This function uses the current colormap to display a series of points
as a triangular surface plot. It will use a Delaunay triangulation to
interpolate the z values between x and y values. If the series of points
is concave, this can lead to interpolation artifacts on the edges of the
plot, as the interpolation may occur in very acute triangles.

:param x: the x coordinates to plot
:param y: the y coordinates to plot
:param z: the z coordinates to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example point data
    julia> x = 8 .* rand(100) .- 4
    julia> y = 8 .* rand(100) .- 4
    julia> z = sin.(x) .+ cos.(y)
    julia> # Draw the triangular surface plot
    julia> trisurf(x, y, z)
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
Draw a heatmap.

This function uses the current colormap to display a two-dimensional
array as a heatmap. The array is drawn with its first value in the bottom
left corner, so in some cases it may be neccessary to flip the columns
(see the example below).

By default the function will use the column and row indices for the x- and
y-axes, respectively, so setting the axis limits is recommended. Also note that the
values in the array must lie within the current z-axis limits so it may
be neccessary to adjust these limits or clip the range of array values.

:param data: the heatmap data

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw the heatmap
    julia> heatmap(z)
""")

@plotfunction(polarheatmap, geom = :polarheatmap, axes = :polar, setargs = _setargs_heatmap, kwargs = (colorbar=true, overlay_axes=true, ratio=1.0))

_setargs_hexbin(f, x, y; kwargs...) = ((x, y, emptyvector(Float64), [0.0, 1.0]), kwargs)

@plotfunction(hexbin, geom = :hexbin, axes = :axes2d, setargs = _setargs_hexbin,
kwargs = (colorbar=true,), docstring="""
Draw a hexagon binning plot.

This function uses hexagonal binning and the the current colormap to
display a series of points. It  can receive one or more of the following:

- x values and y values, or
- x values and a callable to determine y values, or
- y values only, with their indices as x values

:param args: the data to plot

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = randn(100000)
    julia> y = randn(100000)
    julia> # Draw the hexbin plot
    julia> hexbin(x, y)
""")

# Needs to be extended
function colormap()
    rgb = zeros(256, 3)
    for colorind in 1:256
        color = GR.inqcolor(999 + colorind)
        rgb[colorind, 1] = float( color        & 0xff) / 255.0
        rgb[colorind, 2] = float((color >> 8)  & 0xff) / 255.0
        rgb[colorind, 3] = float((color >> 16) & 0xff) / 255.0
    end
    rgb
end

"""
    to_rgba(value, cmap)

Transform a normalized value into a color index given by the colormap `cmap`.
"""
function to_rgba(value, cmap)
    if !isnan(value)
        r, g, b = cmap[round(Int, value * 255 + 1), :]
        a = 1.0
    else
        r, g, b, a = zeros(4)
    end
    round(UInt32, a * 255) << 24 + round(UInt32, b * 255) << 16 +
    round(UInt32, g * 255) << 8  + round(UInt32, r * 255)
end

function _setargs_imshow(f, data; kwargs...)
    if isa(data, AbstractString)
        w, h, rgbdata = GR.readimage(data)
    else
        h, w = size(data)
        cmap = colormap()
        rgbdata = [to_rgba(value, cmap) for value ∈ transpose(data)]
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
Draw an image.

This function can draw an image either from reading a file or using a
two-dimensional array and the current colormap.

:param image: an image file name or two-dimensional array

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = LinRange(-2, 2, 40)
    julia> y = LinRange(0, pi, 20)
    julia> z = sin.(x') .+ cos.(y)
    julia> # Draw an image from a 2d array
    julia> imshow(z)
    julia> # Draw an image from a file
    julia> imshow("example.png")
""")

function _setargs_isosurf(f, v, isovalue; color = [0.0, 0.5, 0.8], kwargs...)
    values = round.((v .- _min(v)) ./ (_max(v) .- _min(v)) .* (2^16-1))
    dimensions = float.(collect(size(v)))
    isoval_norm = (isovalue - _min(v)) / (_max(v) - _min(v))
    # x = dimensions, y = isovalue, z = values, c = color
    ((dimensions, [isoval_norm], values[:], collect(color)), kwargs)
end

@plotfunction(isosurface, geom = :isosurf, axes = :axes3d, setargs = _setargs_isosurf,
kwargs = (xticks=NULLPAIR, yticks=NULLPAIR, zticks=NULLPAIR, ratio=1.0, gr3=true), docstring="""
Draw an isosurface.

This function can draw an image either from reading a file or using a
two-dimensional array and the current colormap. Values greater than the
isovalue will be seen as outside the isosurface, while values less than
the isovalue will be seen as inside the isosurface.

:param v: the volume data
:param isovalue: the isovalue

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> s = LinRange(-1, 1, 40)
    julia> v = 1 .- (s .^ 2 .+ s' .^ 2 .+ reshape(s,1,1,:) .^ 2) .^ 0.5
    julia> # Draw an image from a 2d array
    julia> isosurface(v, isovalue=0.2)
""")

@plotfunction(shade, geom = :shade, axes = :axes2d, kwargs = (tickdir=-1,), docstring="""
Draw a point or line based heatmap.

This function uses the current colormap to display a series of points or polylines. For line data, NaN values can be used as separator.

:param args: the data to plot
:param xform: the transformation type used for color mapping

The available transformation types are:

    +----------------+-+-------------------+
    |   XFORM_BOOLEAN|0|boolean            |
    +----------------+-+-------------------+
    |    XFORM_LINEAR|1|linear             |
    +----------------+-+-------------------+
    |       XFORM_LOG|2|logarithmic        |
    +----------------+-+-------------------+
    |    XFORM_LOGLOG|3|double logarithmic |
    +----------------+-+-------------------+
    |     XFORM_CUBIC|4|cubic              |
    +----------------+-+-------------------+
    | XFORM_EQUALIZED|5|histogram equalized|
    +----------------+-+-------------------+

**Usage examples:**

.. code-block:: julia

    # Create point data
    julia> x = randn(100_000)
    julia> y = randn(100_000)
    julia> shade(x, y)
    julia> # Create line data with NaN as polyline separator
    julia> x = [randn(10000); NaN; randn(10000)]
    julia> x = [randn(10000); NaN; randn(10000)]
    julia> shade(x, y)
""")

function _setargs_volume(f, v::Array{T, 3}; kwargs...) where {T}
    (nx, ny, nz) = size(v)
    (([nx], [ny], [nz], vec(v)), kwargs)
end

@plotfunction(volume, geom = :volume, axes = :axes3d, setargs = _setargs_volume,
kwargs = (colorbar=true,), docstring="""
Draw a volume.

This function can draw a three-dimensional numpy array using volume rendering. The volume data is reduced to a two-dimensional image using an emission or absorption model or by a maximum intensity projection. After the projection the current colormap is applied to the result.

:param v: the volume data
:param algorithm: the algorithm used to reduce the volume data. Available algorithms are “maximum”, “emission” and “absorption”.

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> s = LinRange(-1, 1, 40)
    julia> v = 1 .- (x.^2 .+ y'.^2 .+ reshape(z,1,1,:).^2).^0.5 - 0.25 .* rand(40, 40, 40)
    julia> # Draw the 3d volume data
    julia> volume(v)
    julia> # Draw the 3d volume data using an emission model
    julia> volume(v, algorithm=2)
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
Draw one or more line plots over another plot.
This function can receive one or more of the following:
- x values and y values, or
- x values and a callable to determine y values, or
- y values only, with their indices as x values
:param args: the data to plot
**Usage examples:**
.. code-block:: julia
    julia> # Create example data
    julia> x = LinRange(-2, 2, 40)
    julia> y = 2 .* x .+ 4
    julia> # Draw the first plot
    julia> plot(x, y)
    julia> # Plot graph over it
    julia> oplot(x, x -> x^3 + x^2 + x)
"""
oplot(args...; kwargs...) = oplot!(gcf(), args...; kwargs...)

"""
Save the current figure to a file.

This function draw the current figure using one of GR's workstation types
to create a file of the given name. Which file types are supported depends
on the installed workstation types, but GR usually is built with support
for .png, .jpg, .pdf, .ps, .gif and various other file formats.

:param filename: the filename the figure should be saved to

**Usage examples:**

.. code-block:: julia

    julia> # Create a simple plot
    julia> x = 1:100
    julia> plot(x, 1 ./ (x .+ 1))
    julia> # Save the figure to a file
    julia> savefig("example.png")
"""
function savefig(filename, fig=gcf())
    GR.beginprint(filename)
    draw(fig)
    GR.endprint()
end

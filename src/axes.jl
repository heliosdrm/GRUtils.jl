# Type aliases
const AxisRange = Tuple{Float64, Float64}
const AxisTickData  = Tuple{Float64, Tuple{Float64,Float64}, Int}

"""
    Axes(kind::Symbol [; kwargs...])

`Axes` is a type of objects that contain the graphical specifications of the
coordinate system of a plot.

`Axes` are determined by their `kind`, which may be `:axes2d` for 2-D plots,
`:axes3d` for 3-D plots, and `:polar` for polar plots. The rest of its fields
can be passed to the `Axes` constructor as keyword arguments (and they are set
to "empty" or "null" values if not given). Those fields are:

* `ranges`: boundaries of the different axes/scales. They are given as a dictionary
    whose keys are `Symbol`s with the name of the axis (`:x`, `:y`, `:z`, `:c`),
    and whose values are tuples with two float values &mdash;
    the minimum and maximum values, respectively.
    The range `(Inf, -Inf)` describes an undefined axis.
* `tickdata`: numeric specifications of the "ticks" that are drawn on the axes.
    They are given as a dictionary whose keys are the names of the axis (as for `range`),
    and whose values are tuples that contain for that axis: (1) the "minor" value
    between consecutive ticks; (2) a tuple with the two ends of the axis ticks; and
    (3) the number of minor ticks between "major", numbered ticks.
* `ticklabels`: transformations between tick values and labels. They are given
    as a dictionary whose keys are the names of the axis, and whose values are
    functions that accept a number as argument, and return a `String` with the
    text that must be written at major ticks. (This only works for the X and Y axes).
* `perspective`: A `Vector{Int}` that contains the "rotation" and "tilt" angles
    that are used to project 3-D axes on the plot plane. (Only for 3-D plots)
* `options`: A `Dict{Symbol, Int}` with extra options that control the visualization
    of the axes. Currently supported options are:
    + `options[:scale]`, an integer code that defines what axes are must be
        plotted in log scale or reversed (cf. [`GR.setscale`](@ref)).
    + `options[:grid] = 0` to hide the plot grid, or any other value to show it.
    + `options[:tickdir]` to determine how the ticks are drawn
        (positive value to draw them inside the plot area, negative value to
        draw them outside, or `0` to hide them).

### Alternative constructor

    Axes(K::Val{kind}, geoms::Array{<:Geometry} [; kwargs...]) where kind

An `Axes` object can also be made by defining the kind of the axes in a `Val`
object (`Val(:axes2d)`, `Val(:axes3d)`, etc.), and a vector of [`Geometry`](@ref)
objects that are used to calculate the different axis limits, ticks, etc.
"""
struct Axes
    kind::Symbol
    ranges::Dict{Symbol, AxisRange}
    tickdata::Dict{Symbol, AxisTickData}
    ticklabels::Dict{Symbol, <:Function}
    perspective::Vector{Int}
    options::Dict{Symbol, Int}
end

Axes(kind::Symbol; ranges = Dict{Symbol, AxisRange}(),
    tickdata = Dict{Symbol, AxisTickData}(),
    ticklabels = Dict{Symbol, Function}(),
    perspective = Int[],
    options = Dict{Symbol, Int}()) =
    Axes(kind, ranges, tickdata, ticklabels, perspective, options)

function Axes(K::Val{kind}, geoms::Array{<:Geometry}; panzoom=nothing, kwargs...) where kind
    # Set limits based on data
    rangevalues = minmax(geoms; kwargs...)
    ranges = Dict(zip((:x, :y, :z, :c), rangevalues))
    adjustranges!(ranges, panzoom; kwargs...)
    # Configure axis scale and ticks
    tickdata = set_ticks(K, ranges; kwargs...)
    # Tick labels
    ticklabels = set_ticklabels(K; kwargs...)
    perspective = set_perspective(K; kwargs...)
    options = Dict{Symbol, Int}(
        :scale => set_scale(K; kwargs...),
        :grid => Int(get(kwargs, :grid, 1))
        )
    haskey(kwargs, :tickdir) && (options[:tickdir] = kwargs[:tickdir])
    Axes(kind, ranges, tickdata, ticklabels, perspective, options)
end

# Calculation of data ranges

"""
    minmax(args...)

Calculate the ranges of a given array of values, a `Geometry` or a collection of `Geometry`
"""
# Nested definitions of minmax: for array, Geometry and Array of Geometries
function minmax(x::AbstractVecOrMat{<:Real}, (min_prev, max_prev))
    isempty(x) && return (float(min_prev), float(max_prev))
    x0, x1 = extrema64(x)
    newmin = min(x0, min_prev)
    newmax = max(x1, max_prev)
    return (newmin, newmax)
end

function minmax(g::Geometry, xminmax, yminmax, zminmax, cminmax)
    xminmax = minmax(g.x, xminmax)
    yminmax = minmax(g.y, yminmax)
    zminmax = minmax(g.z, zminmax)
    if isempty(g.c)
        cminmax = minmax(g.z, cminmax)
    else
        cminmax = minmax(g.c, cminmax)
    end
    return xminmax, yminmax, zminmax, cminmax
end

function minmax(geoms::Array{<:Geometry}; kwargs...)
    # Calculate ranges of given values
    xminmax = yminmax = zminmax = cminmax = extrema64(Float64[])
    for g in geoms
        xminmax, yminmax, zminmax, cminmax = minmax(g, xminmax, yminmax, zminmax, cminmax)
    end
    # Adjust ranges
    (xminmax == (Inf, -Inf)) && (xminmax = (0.0, 1.0))
    (yminmax == (Inf, -Inf)) && (yminmax = (0.0, 1.0))
    xminmax = fix_minmax(xminmax...)
    yminmax = fix_minmax(yminmax...)
    zminmax = fix_minmax(zminmax...)
    # Return values
    xrange = get(kwargs, :xlim, xminmax)
    yrange = get(kwargs, :ylim, yminmax)
    zrange = get(kwargs, :zlim, zminmax)
    crange = get(kwargs, :clim, cminmax)
    return xrange, yrange, zrange, crange
end

"""
    extrema64(a)

Compute both the minimum and maximum element and return them as a 2-tuple.
This is approximately like `extrema` in the standard library, but always
returns a tuple of `Float64` values, ignores `NaN`, and returns `(Inf, -Inf)`
for inputs that are empty or only contain `NaN`.
"""
function extrema64(a)
    amin =  typemax(Float64)
    amax = -typemax(Float64)
    for el in a
        if !isnan(el)
            if isnan(amin) || el < amin
                amin = Float64(el)
            end
            if isnan(amax) || el > amax
                amax = Float64(el)
            end
        end
    end
    amin, amax
end

"""
    fix_minmax(a, b)

Adjust `a` and `b` to avoid that they coincide.
"""
function fix_minmax(a, b)
    if a == b
        a -= a != 0 ? 0.1 * a : 0.1
        b += b != 0 ? 0.1 * b : 0.1
    end
    a, b
end

# Adjust ranges

"""
    adjustranges!(ranges, panzoom; kwargs...)

Adjust the pre-calculated ranges of `Axes` &mdash; see [`minmax`](@ref),
to make them near to integers or "small decimals". This takes into account
if there is a specific "pan" and/or "zoom" set on the axes
(`panzoom`, cf. [`GR.panzoom`](@ref)). Explicit axes limits or log scales
are also considered, through keyword arguments `xlim`, `ylim`, etc. (given as
2-tuples) or `xlog` `ylog`, etc. (given as `Bool`).
"""
function adjustranges!(ranges::Dict{Symbol, AxisRange}, panzoom::Nothing; kwargs...)
    for axname in keys(ranges)
        keylim = Symbol(axname, :lim)
        keylog = Symbol(axname, :log)
        if !haskey(kwargs, keylim) && !get(kwargs, keylog, false)
            amin, amax = ranges[axname]
            if isfinite(amin) && isfinite(amax)
                ranges[axname] = GR.adjustlimits(amin, amax)
            end
        end
    end
end

function adjustranges!(ranges::Dict{Symbol, AxisRange}, panzoom; kwargs...)
    xmin, xmax, ymin, ymax = GR.panzoom(panzoom...)
    ranges[:x] = (xmin, xmax)
    ranges[:y] = (ymin, ymax)
end

# Set ticks for the different types of axes

"""
    set_ticks(K, ranges; kwargs...)

Define the tick numeric specifications of a given `Axes`, taking into
account its `kind` and calculated `ranges` &mdash; see [`minmax`](@ref).
The `kind` is passed as a `Val` object (`Val(:axes2d)`, `Val(:axes3d)`, etc.).
in the first argument. Keyword arguments are used to adjust the tick intervals
and limits if the axes are set in log scale (`xlog`, `ylog`, etc.,
given as `Bool` values), or if they are reversed (`xflip`, `yflip`, etc.,
also given as `Bools`).
"""
function set_ticks(::Val{:axes2d}, ranges; kwargs...)
    major_count = 5
    xaxis = set_axis(:x, ranges[:x], major_count; kwargs...)
    yaxis = set_axis(:y, ranges[:y], major_count; kwargs...)
    Dict(:x => xaxis, :y => yaxis)
end

function set_ticks(::Val{:axes3d}, ranges; kwargs...)
    major_count = 2
    xaxis = set_axis(:x, ranges[:x], major_count; kwargs...)
    yaxis = set_axis(:y, ranges[:y], major_count; kwargs...)
    zaxis = set_axis(:z, ranges[:z], major_count; kwargs...)
    Dict(:x => xaxis, :y => yaxis, :z => zaxis)
end

function set_ticks(::Val{:polar}, ranges; kwargs...)
    major_count = 2
    xaxis = set_axis(:x, ranges[:x], major_count; kwargs..., xlog=false, xflip=false)
    yaxis = set_axis(:y, ranges[:y], major_count; kwargs..., ylog=false, yflip=false)
    Dict(:x => xaxis, :y => yaxis)
end

set_ticks(::Any, ranges; kwargs...) = Dict{Symbol, AxisTickData}()

function set_axis(axname, axrange, major; kwargs...)
    if get(kwargs, Symbol(axname, :log), false)
        tick = 10
        major = 1
    else
        keyticks = Symbol(axname, :ticks)
        if haskey(kwargs, keyticks)
            tick, major = kwargs[keyticks]
        else
            tick = GR.tick(axrange...) / major
        end
    end
    org = get(kwargs, Symbol(axname, :flip), false) ? reverse(axrange) : axrange
    return tick, org, major
end

# Set tick labels - only working for axes2d

"""
    set_ticklabels(K; kwargs...)

Define the tick label transformation functions for `Axes`, using the
keyword arguments `xticklabels` or `yticklabels` (if they are given).
This is only used for axes of `kind == :axes2d`. The kind of the axes is passed
in the first argument as a `Val` object (i.e. `Val(:axes2d)`, etc.).

The keyword arguments may be functions that transform numbers into strings,
or collection of strings that are associated to the sequence of integers `1, 2, ...`.
"""
function set_ticklabels(::Val{:axes2d}; kwargs...)
    ticklabels = Dict{Symbol, Function}()
    if haskey(kwargs, :xticklabels) || haskey(kwargs, :yticklabels)
        ticklabels[:x] = get(kwargs, :xticklabels, identity) |> ticklabel_fun
        ticklabels[:y] = get(kwargs, :yticklabels, identity) |> ticklabel_fun
    end
    return ticklabels
end

set_ticklabels(::Any; kwargs...) = Dict{Symbol, Function}()

function ticklabel_fun(f::Function)
    return (x, y, svalue, value) -> GR.textext(x, y, string(f(value)))
end

function ticklabel_fun(labels::AbstractVecOrMat{T}) where T <: AbstractString
    (x, y, svalue, value) -> begin
        pos = findfirst(t->(value≈t), collect(1:length(labels)))
        lab = (pos == nothing) ? "" : labels[pos]
        GR.textext(x, y, lab)
    end
end

# Set scale

"""
    set_scale(K; kwargs...)

Set the scale characteristics of the axes (logarithmic or flipped axes),
taking into account the kind of the axes, and keyword arguments that determine
which axes are in logarithmic scale (`xlog`, `ylog`, etc., given as `Bool` values)
and which ones are flipped (`xflip`, `yflip`, etc. also given as `Bool`s).

Scale specifications are ignored for axes of `kind == :polar`.
The kind of the axes is passed in the first argument as a `Val` object
(i.e. `Val(:axes2d)`, etc.).

The result is an integer code used by the low level function [`GR.setscale`](@ref).
"""
function set_scale(::Any; kwargs...)
    scale = 0
    get(kwargs, :xlog, false) && (scale |= GR.OPTION_X_LOG)
    get(kwargs, :ylog, false) && (scale |= GR.OPTION_Y_LOG)
    get(kwargs, :zlog, false) && (scale |= GR.OPTION_Z_LOG)
    get(kwargs, :xflip, false) && (scale |= GR.OPTION_FLIP_X)
    get(kwargs, :yflip, false) && (scale |= GR.OPTION_FLIP_Y)
    get(kwargs, :zflip, false) && (scale |= GR.OPTION_FLIP_Z)
    return scale
end

set_scale(::Val{:polar}; kwargs...) = 0

# Set the perspective (only for axes3d)

"""
    set_perspective(K; kwargs...)

Set the perspective of the plot, using the keyword arguments `rotation` and `tilt`.

Scale specifications are only used for axes of `kind == :axes3d`.
The kind of the axes is passed in the first argument as a `Val` object
(i.e. `Val(:axes2d)`, etc.).
"""
function set_perspective(::Val{:axes3d}; kwargs...)
    rotation = Int(get(kwargs, :rotation, 40))
    tilt = Int(get(kwargs, :tilt, 70))
    [rotation, tilt]
end

set_perspective(::Any; kwargs...) = [0, 0]

####################
## `draw` methods ##
####################

function draw(ax::Axes)
    # Special draw function for polar axes
    ax.kind == :polar && return draw_polaraxes(ax)
    # Set the window of data seen
    GR.setwindow(ax.ranges[:x]..., ax.ranges[:y]...)
    # Modify scale (log or flipped axes)
    GR.setscale(ax.options[:scale])
    # Set the specifications of guides (grid and ticks)
    GR.setlinecolorind(1)
    GR.setlinewidth(1)
    ticksize, charheight = _tickcharheight()
    haskey(ax.options, :tickdir) && (ticksize *= ax.options[:tickdir])
    GR.setcharheight(charheight)
    xtick, xorg, majorx = ax.tickdata[:x]
    ytick, yorg, majory = ax.tickdata[:y]
    # Branching for different kinds of axes
    if ax.kind == :axes3d
        GR.setspace(ax.ranges[:z]..., ax.perspective...)
        ztick, zorg, majorz = ax.tickdata[:z]
        # Draw ticks as 2-D if it is the XY plane
        if ax.perspective == [0, 90]
            (ax.options[:grid] ≠ 0) && GR.grid(xtick, ytick, 0, 0, majorx, majory)
            GR.axes(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize)
            GR.axes(xtick, ytick, xorg[2], yorg[2], -majorx, -majory, -ticksize)
        else
            if (ax.options[:grid] ≠ 0)
                GR.grid3d(xtick, 0, ztick, xorg[1], yorg[2], zorg[1], 2, 0, 2)
                GR.grid3d(0, ytick, 0, xorg[1], yorg[2], zorg[1], 0, 2, 0)
            end
            GR.axes3d(xtick, 0, ztick, xorg[1], yorg[1], zorg[1], majorx, 0, majorz, -ticksize)
            GR.axes3d(0, ytick, 0, xorg[2], yorg[1], zorg[1], 0, majory, 0, ticksize)
        end
    elseif ax.kind == :axes2d
        (ax.options[:grid] ≠ 0) && GR.grid(xtick, ytick, 0, 0, majorx, majory)
        if !isempty(ax.ticklabels)
            fx, fy = ax.ticklabels[:x], ax.ticklabels[:y]
            GR.axeslbl(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize, fx, fy)
        else
            GR.axes(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize)
        end
        GR.axes(xtick, ytick, xorg[2], yorg[2], -majorx, -majory, -ticksize)
    end
    return nothing
end

function draw_polaraxes(ax)
    # Set the window as the unit circle
    GR.setwindow(-1.0, 1.0, -1.0, 1.0)
    # Modify scale (log or flipped axes)
    GR.setscale(ax.options[:scale]) # ??
    # Set the specifications of guides (grid and ticks)
    GR.savestate()
    GR.setlinewidth(1)
    _, charheight = _tickcharheight()
    GR.setcharheight(charheight)
    GR.setlinetype(GR.LINETYPE_SOLID)
    rmin, rmax = ax.ranges[:y]
    tick = 0.5 * GR.tick(rmin, rmax)
    # Draw the arcs and radii
    n = round(Int, (rmax - rmin) / tick + 0.5)
    for i in 0:n
        r = float(i) / n
        if i % 2 == 0
            GR.setlinecolorind(88)
            if i > 0
                GR.drawarc(-r, r, -r, r, 0, 359)
            end
            GR.settextalign(GR.TEXT_HALIGN_LEFT, GR.TEXT_VALIGN_HALF)
            x, y = GR.wctondc(0.05, r)
            rounded = round(rmin + i * tick, sigdigits = 12, base = 10)
            GR.text(x, y, string(rounded))
        else
            GR.setlinecolorind(90)
            GR.drawarc(-r, r, -r, r, 0, 359)
        end
    end
    for alpha in 0:45:315
        a = alpha + 90
        sinf = sin(a * π / 180)
        cosf = cos(a * π / 180)
        GR.polyline([sinf, 0], [cosf, 0])
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_HALF)
        x, y = GR.wctondc(1.1 * sinf, 1.1 * cosf)
        GR.textext(x, y, string(alpha, "^o"))
    end
    GR.restorestate()
    return nothing
end

"""
    _tickcharheight(vp)

Return the size of the tick characters and the height of the tick marks,
proportional to the size of the rectangle defined by `vp`.
"""
function _tickcharheight(vp=GR.inqviewport())
    diag = sqrt((vp[2] - vp[1])^2 + (vp[4] - vp[3])^2)
    ticksize = 0.0075 * diag
    charheight = max(0.018 * diag, 0.012)
    ticksize, charheight
end

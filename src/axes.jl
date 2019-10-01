# Type aliases
const AxisRange = Tuple{Float64, Float64}
const AxisTickData  = Tuple{Float64, Tuple{Float64,Float64}, Int}

"""
    Axes(kind, ranges, tickdata, ticklabels, perspective, camera, options)

Return an `Axes` object, containing the graphical specifications of the
coordinate system of a plot.

Axes are determined by their `kind`, which may be `:axes2d` for 2-D plots,
`:axes3d` for 3-D plots, and `:polar` for polar plots. The rest of its fields are:

* **`ranges`**: boundaries of the different axes/scales. They are given as a dictionary
    whose keys are symbols with the name of the axis (`:x`, `:y`, `:z`, `:c`),
    and whose values are tuples with two float values — the minimum and maximum
    values, respectively. The range `(Inf, -Inf)` describes an undefined axis.
* **`tickdata`**: numeric specifications of the "ticks" that are drawn on the axes.
    They are given as a dictionary whose keys are the names of the axis (as for `range`),
    and whose values are tuples that contain for that axis: (1) a `Float64` with
    the "minor" value between consecutive ticks; (2) a 2-tuple of `Float64` with
    the ends of the axis ticks; and (3) an `Int` with the number of minor ticks
    between "major", numbered ticks.
* **`ticklabels`**: transformations between tick values and labels. They are given
    as a dictionary whose keys are the names of the axis, and whose values are
    functions that accept a number as argument, and return a string with the
    text that must be written at major ticks. (This only works for the X and Y axes).
* **`perspective`**: A `Vector{Int}` that contains the "rotation" and "tilt" angles
    that are used to project 3-D axes on the plot plane. (Only for 3-D plots)
* **`camera`**: A `Vector{Float64}` with the camera parameters (camera position,
    view center and "up" vector, only used for 3-D plots).
* **`options`**: A `Dict{Symbol, Int}` with extra options that control the visualization
    of the axes. Currently supported options are:
    + `options[:scale]`, an integer code that defines what axes are must be
        plotted in log scale or reversed (cf. the function `GR.setscale`).
    + `options[:grid] = 0` to hide the plot grid, or any other value to show it.
    + `options[:tickdir]` to determine how the ticks are drawn
        (positive value to draw them inside the plot area, negative value to
        draw them outside, or `0` to hide them).
    + `options[:gr3] = 0` to identify if the axes are a 3-D scene defined for the `gr3` interface.
"""
struct Axes
    kind::Symbol
    ranges::Dict{Symbol, AxisRange}
    tickdata::Dict{Symbol, AxisTickData}
    ticklabels::Dict{Symbol, <:Function}
    perspective::Vector{Int}
    camera::Vector{Float64}
    options::Dict{Symbol, Int}
end

"""
    Axes(kind::Symbol [; kwargs...])

Return an `Axes` object with selected parameters given by keyword arguments.

This constructor only requires the `kind` of the axes (`:axes2d`, `:axes3d` or
`:axespolar`), such that all the other parameters are passed as keyword arguments.
Null or empty values are used by default for the parameters that are not given.
"""
Axes(kind::Symbol; ranges = Dict{Symbol, AxisRange}(),
    tickdata = Dict{Symbol, AxisTickData}(),
    ticklabels = Dict{Symbol, Function}(),
    perspective = Int[],
    camera = Float64[],
    options = Dict{Symbol, Int}()) =
    Axes(kind, ranges, tickdata, ticklabels, perspective, camera, options)

"""
    Axes(kind, geoms::Array{<:Geometry} [; kwargs...]) where kind

Return an `Axes` object defined by the `kind` of the axes, and a vector of
[`Geometry`](@ref) objects that are meant to be plotted inside the axes, which
are used to calculate the different axis limits, ticks, etc.
Keyword arguments are used to override the default calculations.
"""
function Axes(kind, geoms::Array{<:Geometry}; grid=1, kwargs...)
    # Set limits based on data
    ranges = minmax(geoms)
    adjustranges!(ranges; kwargs...)
    ticklabels = Dict{Symbol, Function}()
    perspective = [0, 0]
    camera = zeros(9)
    options = Dict{Symbol, Int}(:scale => 0, :grid => 1)
    # Special cases dependin on axis kind
    if kind == :axes2d
        tickdata = set_ticks(ranges, 5, (:x, :y); kwargs...)
        set_ticklabels!(ticklabels; kwargs...)
        options[:scale] = set_scale(; kwargs...)
        options[:grid] = Int(grid)
    elseif kind == :axes3d
        tickdata = set_ticks(ranges, 2, (:x, :y, :z); kwargs...)
        perspective = [Int(get(kwargs, :rotation, 40)), Int(get(kwargs, :tilt, 70))]
        options[:scale] = set_scale(; kwargs...)
        options[:grid] = Int(grid)
        if get(kwargs, :gr3, false)
            options[:gr3] = 1
            cameradistance = get(kwargs, :cameradistance, 3.0)
            camera = set_camera(cameradistance, perspective...; kwargs...)
        end
    elseif kind == :polar
        tickdata = set_ticks(ranges, 2, (:x, :y); kwargs..., xlog=false, ylog=false, xflip=false, yflip=false)
        options[:grid] = Int(grid)
    elseif kind == :camera # Not defined
        tickdata = Dict{Symbol, AxisTickData}()
    end
    haskey(kwargs, :tickdir) && (options[:tickdir] = kwargs[:tickdir])
    Axes(kind, ranges, tickdata, ticklabels, perspective, camera, options)
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

function minmax(geoms::Array{<:Geometry})
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
    return Dict(:x => xminmax, :y => yminmax, :z => zminmax, :c => cminmax)
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
    adjustranges!(ranges; kwargs...)

Adjust the pre-calculated ranges of `Axes` &mdash; see [`minmax`](@ref),
to make them near to integers or "small decimals". Explicit axes limits or log scales
are considered, through keyword arguments `xlim`, `ylim`, etc. (given as
2-tuples) or `xlog` `ylog`, etc. (given as `Bool`).
"""
function adjustranges!(ranges::Dict{Symbol, AxisRange}; kwargs...)
    for axname in keys(ranges)
        keylim = Symbol(axname, :lim)
        if haskey(kwargs, keylim)
            ranges[axname] = kwargs[keylim]
        else
            keylog = Symbol(axname, :log)
            if !get(kwargs, keylog, false)
                amin, amax = ranges[axname]
                if isfinite(amin) && isfinite(amax)
                    ranges[axname] = GR.adjustlimits(amin, amax)
                end
            end
        end
    end
end

# Set ticks for the different types of axes

"""
    set_ticks(ranges, major_count, coordinates; kwargs...)

Define the tick numeric specifications of a given `Axes`, taking into
account its calculated `ranges` &mdash; see [`minmax`](@ref), with a given
number of minor ticks between major ticks (`major_count`). The specifications
are given for the axes defined in `coordinates` as a tuple of symbols
(e.g. `(:x, :y)` for the X and Y axes).
Keyword arguments are used to adjust the tick intervals
and limits if the axes are set in log scale (`xlog`, `ylog`, etc.,
given as `Bool` values), or if they are reversed (`xflip`, `yflip`, etc.,
also given as `Bools`).
"""
function set_ticks(ranges, major_count, coordinates; kwargs...)
    Dict(c => set_axis(c, ranges[c], major_count; kwargs...) for c ∈ coordinates)
end

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
    set_ticklabels!(ticklabels; kwargs...)

Modify the given tick label transformation functions for `Axes`, using the
keyword arguments `xticklabels` or `yticklabels` (if they are given).

The keyword arguments may be functions that transform numbers into strings,
or collection of strings that are associated to the sequence of integers `1, 2, ...`.
"""
function set_ticklabels!(ticklabels; kwargs...)
    if haskey(kwargs, :xticklabels) || haskey(kwargs, :yticklabels)
        ticklabels[:x] = get(kwargs, :xticklabels, identity) |> ticklabel_fun
        ticklabels[:y] = get(kwargs, :yticklabels, identity) |> ticklabel_fun
    end
end

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
    set_scale(; kwargs...)

Set the scale characteristics of the axes (logarithmic or flipped axes),
taking into account the and keyword arguments that determine
which axes are in logarithmic scale (`xlog`, `ylog`, etc., given as `Bool` values)
and which ones are flipped (`xflip`, `yflip`, etc. also given as `Bool`s).

The result is an integer code used by the low level function [`GR.setscale`](@ref).
"""
function set_scale(; kwargs...)
    scale = 0
    get(kwargs, :xlog, false) && (scale |= GR.OPTION_X_LOG)
    get(kwargs, :ylog, false) && (scale |= GR.OPTION_Y_LOG)
    get(kwargs, :zlog, false) && (scale |= GR.OPTION_Z_LOG)
    get(kwargs, :xflip, false) && (scale |= GR.OPTION_FLIP_X)
    get(kwargs, :yflip, false) && (scale |= GR.OPTION_FLIP_Y)
    get(kwargs, :zflip, false) && (scale |= GR.OPTION_FLIP_Z)
    return scale
end

"""
    set_camera(distance, perspective; kwargs...)
"""
function set_camera(distance, rotation, tilt;
    focus = (0.0, 0.0, 0.0), twist = 0.0, kwargs...)

    camera_position = (distance * sind(tilt) * sind(rotation),
                       distance * cosd(tilt),
                       distance* sind(tilt) * cosd(rotation))
    camera_direction = camera_position .- focus
    up_vector = (-sind(twist) * camera_direction[3],
                 cosd(twist),
                 sind(twist) * camera_direction[1])
    return [camera_position..., focus..., up_vector...]
end

####################
## `draw` methods ##
####################

function draw(ax::Axes)
    # Special draw functions for polar axes and gr3
    ax.kind == :polar && return draw_polaraxes(ax)
    if ax.kind == :axes3d
        get(ax.options, :gr3, 0) ≠ 0 && return draw_gr3axes(ax)
    end
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

draw_gr3axes(ax) = GR.gr3.cameralookat(ax.camera...)

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

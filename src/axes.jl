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
    + `options[:gr3] ≠ 0` to identify if the axes are a 3-D scene defined for the `gr3` interface.
    + `options[:radians] = 0` to transform angular values to degrees in polar axes.
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
    # Set limits based on data and scale
    scale = set_scale(; kwargs...)
    ranges = minmax(geoms, scale)
    adjustranges!(ranges; kwargs...)
    ticklabels = Dict{Symbol, Function}()
    perspective = [0, 0]
    camera = zeros(9)
    options = Dict{Symbol, Int}(:scale => scale, :grid => Int(grid))
    # Special cases dependin on axis kind
    if kind == :axes2d
        tickdata = set_ticks(ranges, 5, (:x, :y); kwargs...)
        set_ticklabels!(ticklabels; kwargs...)
    elseif kind == :axes3d
        tickdata = set_ticks(ranges, 2, (:x, :y, :z); kwargs...)
        perspective = [Int(get(kwargs, :rotation, 40)), Int(get(kwargs, :tilt, 70))]
        if get(kwargs, :gr3, false)
            options[:gr3] = 1
            cameradistance = get(kwargs, :cameradistance, 3.0)
            camera = set_camera(cameradistance, perspective...; kwargs...)
        end
    elseif kind == :polar
        tickdata = set_ticks(ranges, 2, (:x, :y); kwargs..., xlog=false, ylog=false, xflip=false, yflip=false)
        options[:scale] = 0
        if !get(kwargs, :radians, true)
            options[:radians] = 0
        end
    else # Not defined
        tickdata = set_ticks(ranges, 0, (:x, :y); kwargs...)
        options[:scale] = 0
        options[:grid] = 1
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
function minmax(x::AbstractVecOrMat{<:Real}, (min_prev, max_prev), skipnegative)
    isempty(x) && return (float(min_prev), float(max_prev))
    if skipnegative
        x = replace(v -> v > 0 ? v : NaN, x)
    end
    x0, x1 = extrema64(x)
    newmin = min(x0, min_prev)
    newmax = max(x1, max_prev)
    return (newmin, newmax)
end

function minmax(g::Geometry, xminmax, yminmax, zminmax, cminmax, scale)
    # skip negative values if log scales:
    xminmax = minmax(g.x, xminmax, scale & GR.OPTION_X_LOG != 0)
    yminmax = minmax(g.y, yminmax, scale & GR.OPTION_Y_LOG != 0)
    zminmax = minmax(g.z, zminmax, scale & GR.OPTION_Z_LOG != 0)
    if isempty(g.c)
        cminmax = minmax(g.z, cminmax, false)
    else
        cminmax = minmax(g.c, cminmax, false)
    end
    return xminmax, yminmax, zminmax, cminmax
end

function minmax(geoms::Array{<:Geometry}, scale=0)
    # Calculate ranges of given values
    xminmax = yminmax = zminmax = cminmax = extrema64(Float64[])
    for g in geoms
        xminmax, yminmax, zminmax, cminmax = minmax(g, xminmax, yminmax, zminmax, cminmax, scale)
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
    set_limits(limits1, limits2)

Return a tuple of lower and upper limits, using the values given in `limits1`,
or those from `limits2` if either value of `limits1` is a `Nothing`.
"""
set_limits(::Tuple{Nothing, Nothing}, limits2) = float.(limits2)
set_limits((n, max1)::Tuple{Nothing, T}, (min2, max2)) where T = float.((min2, max1))
set_limits((min1, n)::Tuple{T, Nothing}, (min2, max2)) where T = float.((min1, max2))
set_limits(limits1, limits2) = float.(limits1)

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
            ranges[axname] = set_limits(kwargs[keylim], ranges[axname])
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
    keyticks = Symbol(axname, :ticks)
    if haskey(kwargs, keyticks)
        tick, major = kwargs[keyticks]
    else
        tick = GR.tick(axrange...) / major
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
    if haskey(kwargs, :xticklabels)
        ticklabels[:x] = ticklabel_fun(kwargs[:xticklabels])
    end
    if haskey(kwargs, :yticklabels)
        ticklabels[:y] = ticklabel_fun(kwargs[:yticklabels])
    end
    return nothing
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

# Camera rotation

function _rotate!(v, angle) # Around the third (vertical) axis
    c = cosd(angle)
    s = sind(angle)
    v[1:2] .= (c*v[1] - s*v[2], s*v[1] + c*v[2])
end

function _tilt!(v, angle) # Around the first (transversal) axis (clockwise)
    c = cosd(angle)
    s = sind(angle)
    v[2:3] .= (c*v[2]  + s*v[3], -s*v[2] + c*v[3])
end

function _focus!(params, target) # Rotate to focus on target point
    oldaxis = normalize([params[4]-params[1], params[5]-params[2], params[6]-params[3]])
    newaxis = normalize([target[1]-params[1], target[2]-params[2], target[3]-params[3]])
    # Use the Rodrigues formula: v2 = v1 + sin(w)û×v1 + (1-cos(w))û×(û×v1)
    f1 = oldaxis × newaxis # sin(w)û
    all(f1 .≈ 0.0) && return nothing
    k = (1/sum(f1.^2))
    f2 = (k - sqrt(k*k-k)) .* f1 # (1-cos(w))û/sin(w)
    vmod = f1 × view(params, 7:9)
    params[4:6] .= target
    params[7:9] .+= vmod .+ f2 × vmod
    return nothing
end

"""
    set_camera(distance, rotation, tilt; focus=zeros(3), twist=0.0)

Return a vector with the 9 camera parameters (camera position, focus and "up" vector),
given the distance from the center of the scene, rotation and tilt angles
in degrees, and optionally (as keyword arguments) one focus point of the
line of sight and the twist angle in degrees.

If `rotation`, `tilt` and `twist` angles are zero, the direction of the line of sight
is the Y axis, and the camera is positioned in the negative direction of that
axis.
"""
function set_camera(distance, rotation, tilt;
    focus = zeros(3), twist = 0.0, kwargs...)

    camera_position = [distance * cosd(tilt) * sind(rotation),
                      -distance * cosd(tilt) * cosd(rotation),
                       distance * sind(tilt)]
    camera_direction = normalize(camera_position .- focus)
    up_vector = [sind(twist), 0, cosd(twist)]
    _tilt!(up_vector, tilt)
    _rotate!(up_vector, rotation)
    parameters = [camera_position..., focus..., up_vector...]
    if any(focus .== 0.0)
        _focus!(parameters, focus)
    end
    return parameters
end

####################
## `draw` methods ##
####################

# Convex hull using Graham's scan - to calculate the frame of 3d plots
function graham_hull(x, y)
    @assert length(x) == length(y) > 2 "lengths of x and y must be equal and greater than 2"
    lowest = argmin(y)
    dx = x .- x[lowest]
    dy = y .- y[lowest]
    # sort by angle
    inds = sortperm(dx ./ sqrt.(dx.^2 .+ dy.^2), rev=true)
    hullx = x[inds[1:2]]
    hully = y[inds[1:2]]
    for i in inds[3:end]
        xn, yn = x[i], y[i] # next
        turnleft = false
        while !turnleft # try until there is a left turn
            dxn = xn - hullx[end]
            dyn = yn - hully[end]
            dxp = hullx[end] - hullx[end-1]
            dyp = hully[end] - hully[end-1]
            turnleft = (dxp*dyn - dxn*dyp >= 0)
            if turnleft # add the point
                push!(hullx, xn)
                push!(hully, yn)
            else # remove the previous point
                pop!(hullx)
                pop!(hully)
            end
        end
    end
    return hullx, hully
end

# Convex frame of 3d axes
function axes3frame(ax::Axes)
    xcorners = zeros(8)
    ycorners = zeros(8)
    i=0
    for xi=(0,1), yi=(0,1), zi=(0,1)
        i = xi*4 + yi*2 + zi + 1
        wc = GR.wc3towc(xi, yi, zi)
        xcorners[i], ycorners[i] = GR.wctondc(wc[1], wc[2])
    end
    hullx, hully = graham_hull(xcorners, ycorners)
end

function fillaxesbackground(ax)
    GR.savestate()
    GR.selntran(0)
    GR.setfillintstyle(GR.INTSTYLE_SOLID)
    GR.setfillcolorind(0)
    if ax.kind == :axes3d
        GR.fillarea(axes3frame(ax)...)
    else
        GR.fillrect(GR.inqviewport()...)
    end
    GR.selntran(1)
    GR.restorestate()
end

function draw(ax::Axes, background=true)
    # Special draw functions for polar axes and gr3
    ax.kind == :polar && return draw_polaraxes(ax, background)
    if ax.kind == :axes3d
        get(ax.options, :gr3, 0) ≠ 0 && return draw_gr3axes(ax)
        GR.setwindow(0, 1, 0, 1)
        GR.setspace(0, 1, ax.perspective...)
    end
    background && fillaxesbackground(ax)
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
    # Modify if xlog, etc.
    if ax.options[:scale] & GR.OPTION_X_LOG != 0
        xtick = 10
        majorx = 1
    end
    if ax.options[:scale] & GR.OPTION_Y_LOG != 0
        ytick = 10
        majory = 1
    end
    # Branching for different kinds of axes
    if ax.kind == :axes3d
        GR.setspace(ax.ranges[:z]..., ax.perspective...)
        ztick, zorg, majorz = ax.tickdata[:z]
        if ax.options[:scale] & GR.OPTION_Z_LOG != 0
            ztick = 10
            majorz = 1
        end
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
            fx = get(ax.ticklabels, :x, ticklabel_fun(identity))
            fy = get(ax.ticklabels, :y, ticklabel_fun(identity))
            GR.axeslbl(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize, fx, fy)
        else
            GR.axes(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize)
        end
        GR.axes(xtick, ytick, xorg[2], yorg[2], -majorx, -majory, -ticksize)
    end
    return nothing
end

function draw_polaraxes(ax, background=true)
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
    rmax = maximum(abs.(ax.ranges[:y]))
    tick = 0.5 * GR.tick(0.0, rmax)
    if background
        # Fill with background color
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        GR.setfillcolorind(0)
        GR.fillarc(-1, 1, -1, 1, 0, 359)
    end
    # Draw the arcs and radii
    n = round(Int, rmax / tick + 0.5)
    for i in 0:n
        r = float(i) / n
        if i % 2 == 0
            GR.setlinecolorind(88)
            if i > 0
                GR.drawarc(-r, r, -r, r, 0, 359)
            end
            GR.settextalign(GR.TEXT_HALIGN_LEFT, GR.TEXT_VALIGN_HALF)
            x, y = GR.wctondc(0.05, r)
            rounded = round(i * tick, sigdigits = 12, base = 10)
            GR.text(x, y, string(rounded))
        else
            GR.setlinecolorind(90)
            GR.drawarc(-r, r, -r, r, 0, 359)
        end
    end
    if get(ax.options, :radians, 1) == 0
        labels = (("$θ^o" for θ in 0:45:315)...,)
    else
        labels = ("0", "\\frac{\\pi}{4}", "\\frac{\\pi}{2}",
            "\\frac{3}{4}\\pi", "\\pi", "\\frac{5}{4}\\pi",
            "\\frac{3}{2}\\pi", "\\frac{7}{4}\\pi")
    end
    for i = 0:7
        sinf = sin(i * 0.25π)
        cosf = cos(i * 0.25π)
        GR.polyline([cosf, 0], [sinf, 0])
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_HALF)
        x, y = GR.wctondc(1.1 * cosf, 1.1 * sinf)
        GR.mathtex(x, y, labels[i + 1])
    end
    GR.restorestate()
    return nothing
end

draw_gr3axes(ax) = GR.gr3.cameralookat(ax.camera...)

"""
    _tickcharheight([vp])

Return the size of the tick marks and the character height,
proportional to the size of the rectangle defined by `vp`
(by default the current viewport).
"""
function _tickcharheight(vp=GR.inqviewport())
    diag = sqrt((vp[2] - vp[1])^2 + (vp[4] - vp[3])^2)
    ticksize = 0.0075 * diag
    charheight = max(0.018 * diag, 0.012)
    ticksize, charheight
end

"""
    charheight([vp])

Return the character height proportional to the size of the
rectangle defined by `vp` (by default the current viewport)
"""
charheight(vp...) = _tickcharheight(vp...)[2]
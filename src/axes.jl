const AxisRange = Tuple{Float64, Float64}
const AxisTickData  = Tuple{Float64,Tuple{Float64,Float64},Int}

"""
:x, :y and optionally :z :
* ranges: minimum and maximum values
* tickdata: minor, origins and major
* ticklabels: functions based on GR.textext
* perspective: rotation and tilt
* options: :scale (code) and :grid (0 is none, others yet undefined)
"""
struct Axes{A}
    ranges::Dict{Symbol, AxisRange}
    tickdata::Dict{Symbol, AxisTickData}
    ticklabels::Dict{Symbol, <:Function}
    perspective::Vector{Int}
    options::Dict{Symbol, Int}
end

# Empty axes constructor
Axes{A}(; ranges = Dict{Symbol, AxisRange}(),
       tickdata = Dict{Symbol, AxisTickData}(),
       ticklabels = Dict{Symbol, Function}(),
       perspective = Int[],
       options = Dict{Symbol, Int}()) where A =
       Axes{A}(ranges, tickdata, ticklabels, perspective, options)

# Constructor with kind, plot data and figure specs (as kwargs...)
function Axes{A}(geoms::Array{<:Geometry}; panzoom=nothing, kwargs...) where {A}
    # Set limits based on data
    rangevalues = minmax(geoms; kwargs...)
    ranges = Dict(zip((:x, :y, :z, :c), rangevalues))
    adjustranges!(ranges, panzoom; kwargs...)
    # Configure axis scale and ticks
    tickdata = set_ticks(Axes{A}, ranges; kwargs...)
    # Tick labels
    ticklabels = set_ticklabels(Axes{A}; kwargs...)
    perspective = set_perspective(Axes{A}; kwargs...)
    options = Dict{Symbol, Int}(
        :scale => set_scale(Axes{A}; kwargs...),
        :grid => Int(get(kwargs, :grid, 1))
        )
    Axes{A}(ranges, tickdata, ticklabels, perspective, options)
end

# Calculation of data ranges
function fix_minmax(a, b)
    if a == b
        a -= a != 0 ? 0.1 * a : 0.1
        b += b != 0 ? 0.1 * b : 0.1
    end
    a, b
end

function Extrema64(a)
    amin =  typemax(Float64)
    amax = -typemax(Float64)
    for el in a
        if !isnan(el)
            if isnan(amin) || el < amin
                amin = el
            end
            if isnan(amax) || el > amax
                amax = el
            end
        end
    end
    amin, amax
end

# Nested definitions of minmax: for array, Geometry and Array of Geometries
function minmax(x::AbstractVecOrMat{<:Real}, (min_prev, max_prev))
    isempty(x) && return (float(min_prev), float(max_prev))
    x0, x1 = Extrema64(x)
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
    xminmax = yminmax = zminmax = cminmax = Extrema64(Float64[])
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

# Adjust ranges (without and with panzoom)
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
function set_ticks(::Type{Axes{:axes2d}}, ranges; kwargs...)
    major_count = 5
    xaxis = set_axis(:x, ranges[:x], 5; kwargs...)
    yaxis = set_axis(:y, ranges[:y], 5; kwargs...)
    Dict(:x => xaxis, :y => yaxis)
end

function set_ticks(::Type{Axes{:axes3d}}, ranges; kwargs...)
    major_count = 2
    xaxis = set_axis(:x, ranges[:x], 2; kwargs...)
    yaxis = set_axis(:y, ranges[:y], 2; kwargs...)
    zaxis = set_axis(:z, ranges[:z], 2; kwargs...)
    Dict(:x => xaxis, :y => yaxis, :z => zaxis)
end

function set_ticks(::Type{Axes{:axespolar}}, ranges; kwargs...)
    major_count = 2
    xaxis = set_axis(:x, ranges[:x], 2; kwargs..., xlog=false, xflip=false)
    yaxis = set_axis(:y, ranges[:y], 2; kwargs..., ylog=false, yflip=false)
    Dict(:x => xaxis, :y => yaxis)
end

set_ticks(::Any, ranges; kwargs...) = Dict{Symbol, AxisTickData}()

function set_axis(axname, axrange, major; kwargs...)
    if get(kwargs, Symbol(axname, :log), false)
        # tick = major = 1
        tick = 10
        major = 1 # enforce scientific notation - in .jlgr.draw_axes
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
function set_ticklabels(::Type{Axes{:axes2d}}; kwargs...)
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

set_scale(::Type{Axes{:axespolar}}; kwargs...) = 0

# Set the perspective (only for axes3d)
function set_perspective(::Type{Axes{:axes3d}}; kwargs...)
    rotation = Int(get(kwargs, :rotation, 40))
    tilt = Int(get(kwargs, :tilt, 70))
    [rotation, tilt]
end

set_perspective(::Any; kwargs...) = [0, 0]

# `draw` methods
function draw(ax::Axes{:axes2d})
    # Set the window of data seen
    GR.setwindow(ax.ranges[:x]..., ax.ranges[:y]...)
    # Modify scale (log or flipped axes)
    GR.setscale(ax.options[:scale])
    # Set the specifications of guides (grid and ticks)
    GR.setlinecolorind(1)
    GR.setlinewidth(1)
    ticksize, charheight = _tickcharheight()
    GR.setcharheight(charheight)
    xtick, xorg, majorx = ax.tickdata[:x]
    ytick, yorg, majory = ax.tickdata[:y]
    # draw
    (ax.options[:grid] != 0) && GR.grid(xtick, ytick, 0, 0, majorx, majory)
    if !isempty(ax.ticklabels)
        fx, fy = ax.ticklabels[:x], ax.ticklabels[:y]
        GR.axeslbl(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize, fx, fy)
    else
        GR.axes(xtick, ytick, xorg[1], yorg[1], majorx, majory, ticksize)
    end
    GR.axes(xtick, ytick, xorg[2], yorg[2], -majorx, -majory, -ticksize)
end

function draw(ax::Axes{:axes3d})
    # Set the window of data seen and the perspective
    GR.setwindow(ax.ranges[:x]..., ax.ranges[:y]...)
    GR.setspace(ax.ranges[:z]..., ax.perspective...)
    # Modify scale (log or flipped axes)
    GR.setscale(ax.options[:scale])
    # Set the specifications of guides (grid and ticks)
    GR.setlinecolorind(1)
    GR.setlinewidth(1)
    ticksize, charheight = _tickcharheight()
    GR.setcharheight(charheight)
    xtick, xorg, majorx = ax.tickdata[:x]
    ytick, yorg, majory = ax.tickdata[:y]
    ztick, zorg, majorz = ax.tickdata[:z]
    # draw
    if (ax.options[:grid] != 0)
        GR.grid3d(xtick, 0, ztick, xorg[1], yorg[2], zorg[1], 2, 0, 2)
        GR.grid3d(0, ytick, 0, xorg[1], yorg[2], zorg[1], 0, 2, 0)
    end
    GR.axes3d(xtick, 0, ztick, xorg[1], yorg[1], zorg[1], majorx, 0, majorz, -ticksize)
    GR.axes3d(0, ytick, 0, xorg[2], yorg[1], zorg[1], 0, majory, 0, ticksize)
end

signif(x, digits; base = 10) = round(x, sigdigits = digits, base = base)

function draw(ax::Axes{:axespolar})
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
            GR.text(x, y, string(signif(rmin + i * tick, 12)))
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
end

function _tickcharheight(vp=GR.inqviewport())
    diag = sqrt((vp[2] - vp[1])^2 + (vp[4] - vp[3])^2)
    ticksize = 0.0075 * diag
    charheight = max(0.018 * diag, 0.012)
    ticksize, charheight
end

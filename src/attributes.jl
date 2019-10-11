const LOCATIONS = ["upper right", "upper left", "lower left", "lower right",
    "right", "center left", "center right", "lower center", "upper center", "center",
    "outer upper right", "outer center right", "outer lower right"]

# Legend
function legend!(p::PlotObject, args...; location=1, kwargs...)
    location = _index(location, LOCATIONS, 1, 0)
    # Reset main viewport if there was a legend
    if haskey(p.attributes, :location) && p.attributes[:location] ∈ LEGEND_LOCATIONS[:right_out]
        p.viewport.inner[2] += p.legend.size[1]
    end
    for i = 1:min(length(args), length(p.geoms))
        p.geoms[i] = Geometry(p.geoms[i], label=args[i])
    end
    maxrows = Int(get(kwargs, :maxrows, length(p.geoms)))
    p.legend = Legend(p.geoms, maxrows)
    # Redefine viewport if legend is set outside
    if p.legend.size ≠ NULLPAIR && location ∈ LEGEND_LOCATIONS[:right_out]
        p.viewport.inner[2] -= p.legend.size[1]
    end
    p.attributes[:location] = location
end

legend!(f::Figure, args...; kwargs...) = legend!(currentplot(f), args...; kwargs...)

"""
    legend(labels...; kwargs...)

Set the legend of the plot, using a series of `labels` (strings).

In addition to the legend strings, the keyword argument
`location` can be used to define the location of the legend with
respect to the plot axes and the keyword argument `maxrows`
to distribute the legend labels in a grid with a maximum number of rows.

Locations are defined as a number or a string, as indicated
in the following table --- based on the convention of
[Matplotlib legends](https://matplotlib.org/3.1.1/api/_as_gen/matplotlib.pyplot.legend.html):

|⁣#  | String                |
|--:|:----------------------|
|  0| `"none"`              |
|  1| `"upper right"`       |
|  2| `"upper left"`        |
|  3| `"lower left"`        |
|  4| `"lower right"`       |
|  5| `"right"`             |
|  6| `"center left"`       |
|  7| `"center right"`      |
|  8| `"lower center"`      |
|  9| `"upper center"`      |
| 10| `"center"`            |
| 11| `"outer upper right"` |
| 12| `"outer center right"`|
| 13| `"outer lower right"` |

The labels are assigned to the geometries contained in the plot,
in the same order as they were created. Only geometries with non-empty labels
and an available guide for legends will be presented in the legend.

# Examples

```julia
# Set the legends to "a" and "b"
legend("a", "b")
```
"""
function legend(args::AbstractString...; kwargs...)
    f = gcf()
    legend!(currentplot(f), args...; kwargs...)
    draw(f)
end

# Hold
hold!(p::PlotObject, state::Bool) = (p.attributes[:hold] = state)

hold!(f::Figure, state) = hold!(currentplot(f), state)

"""
    hold(flag::Bool)

Set the hold flag for combining multiple plots.

`hold(true)` prevents clearing previous plots, so that next plots
will be drawn on top of the previous one until `hold(false)` is called.

Use the keyword argument `hold=<true/false>` in plotting functions, to
set the hold flag during the creation of plots.
"""
hold(state) = hold!(currentplot(gcf()), state)

# Title
function title!(p::PlotObject, s)
    if isempty(s)
        delete!(p.attributes, :title)
    else
        p.attributes[:title] = s
    end
    return nothing
end

title!(f::Figure, s) = title!(currentplot(f), s)

"""
    title(s)

Set the plot title as the string `s`.

Use the keyword argument `title=s` in plotting functions, to
set the title during the creation of plots.

# Examples

```julia
# Set the plot title to "Example Plot"
title("Example Plot")
# Clear the plot title
title("")
```
"""
function title(s::AbstractString)
    f = gcf()
    title!(currentplot(f), s)
    draw(f)
end

const AXISLABEL_DOC = """
    xlabel(s)
    ylabel(s)
    zlabel(s)

Set the X, Y or Z axis labels as the string `s`.

Use the keyword argument `xlab=s`, etc. in plotting functions, to
set the axis labels during the creation of plots.

# Examples

```julia
# Set the x-axis label to "x"
xlabel("x")
# Clear the y-axis label
ylabel("")
```
"""

const TICKS_DOC = """
    xticks(minor[, major = 1])
    yticks(minor[, major = 1])
    zticks(minor[, major = 1])

Set the `minor`intervals of the ticks for the X, Y or Z axis,
and (optionally) the number of minor ticks between `major` ticks.

Use the keyword argument `xticks=(minor, major)`, etc. in plotting functions, to
set the tick intervals during the creation of plots (both the minor and major
values are required in this case).

# Examples

```julia
# Minor ticks every 0.2 units in the X axis
xticks(0.2)
# Major ticks every 1 unit (5 minor ticks) in the Y axis
yticks(0.2, 5)
```
"""

# Attributes for axes

const AXISLIM_DOC = """
    xlim(inf, sup [, adjust::Bool = false])
    xlim((inf, sup), ...)
    ylim(inf, sup, ...)
    ylim((inf, sup), ...)
    zlim(inf, sup, ...)
    zlim((inf, sup), ...)

Set the limits for the plot axes.

The axis limits can either be passed as individual arguments or as a
tuple of `(inf, sup)` values. Setting either limit to `nothing` will
cause it to be automatically determined based on the data, which is the
default behavior.

Additionally to the limits, the flag `adjust` can be used to
tell whether or not the limits have to be adjusted.

Use the keyword argument `xlim=(inf, sup)`, etc. in plotting functions, to
set the axis limits during the creation of plots (`nothing` values are not
allowed in this case).

# Examples

```julia
# Set the x-axis limits to -1 and 1
xlim((-1, 1))
# Reset the x-axis limits to be determined automatically
xlim()
# Set the y-axis upper limit and set the lower limit to 0
ylim((0, nothing))
# Reset the y-axis lower limit and set the upper limit to 1
ylim((nothing, 1))
```
"""

const AXISLOG_DOC = """
    xlog(flag::Bool)
    ylog(flag::Bool)
    zlog(flag::Bool)

Set the X-, Y- or Z-axis to be drawn in logarithmic scale.

Use the keyword argument `xlog=<true/false>`, etc. in plotting functions, to
set the logarithmic axes during the creation of plots.

# Examples

```julia
# Set the x-axis limits to log scale
xlog(true)
# Ensure that the y-axis is in linear scale
ylog(false)
```
"""

const AXISFLIP_DOC = """
    xflip(flag::Bool)
    yflip(flag::Bool)
    zflip(flag::Bool)

Reverse the direction of the X-, Y- or Z-axis.

Use the keyword argument `xflip=<true/false>`, etc. in plotting functions, to
set reversed axes during the creation of plots.

# Examples

```julia
# Reverse the x-axis
xflip(true)
# Ensure that the y-axis is not reversed
yflip(false)
```
"""

for ax = ("x", "y", "z")
    # xlabel, etc.
    fname! = Symbol(ax, :label!)
    fname = Symbol(ax, :label)
    @eval function $fname!(p::PlotObject, s)
        if isempty(s)
            delete!(p.attributes, Symbol($ax, :label))
        else
            p.attributes[Symbol($ax, :label)] = s
        end
        return nothing
    end
    @eval $fname!(f::Figure, s) = $fname!(currentplot(f), s)
    @eval @doc AXISLABEL_DOC function $fname(s::AbstractString)
        f = gcf()
        $fname!(currentplot(f), s)
        draw(f)
    end

    # xticks, etc.
    fname! = Symbol(ax, :ticks!)
    fname = Symbol(ax, :ticks)
    @eval function $fname!(p::PlotObject, minor, major=1)
        tickdata = p.axes.tickdata
        if haskey(tickdata, Symbol($ax))
            tickdata[Symbol($ax)] = (float(minor), tickdata[Symbol($ax)][2], Int(major))
        end
        p.attributes[Symbol($ax, :ticks)] = (minor, major)
        return nothing
    end
    @eval $fname!(f::Figure, args...) = $fname!(currentplot(f), args...)
    @eval @doc TICKS_DOC function $fname(args...)
        f = gcf()
        $fname!(currentplot(f), args...)
        draw(f)
    end

    # xlim, etc.
    fname! = Symbol(ax, :lim!)
    fname = Symbol(ax, :lim)
    @eval function $fname!(p::PlotObject, (minval, maxval), adjust::Bool=false)
        nomin = isa(minval, Nothing)
        nomax = isa(maxval, Nothing)
        fullrange = (nomin || nomax) ? minmax(p.geoms)[Symbol($ax)] : float.((minval, maxval))
        if nomin && !nomax     # (::Nothing, ::Number)
            limits = (fullrange[1], float(maxval))
        elseif !nomin && nomax # (::Number, Nothing)
            limits = (float(minval), fullrange[2])
        else # (::Number, ::Number) or (::Nothing, ::Nothing)
            limits = fullrange
        end
        adjust && (limits = GR.adjustlimits(limits...))
        p.axes.ranges[Symbol($ax)] = limits
        tickdata = p.axes.tickdata
        if haskey(tickdata, Symbol($ax))
            axisticks = tickdata[Symbol($ax)]
            tickdata[Symbol($ax)] = (axisticks[1], limits, axisticks[3])
        end
        p.attributes[Symbol($ax, :lim)] = (minval, maxval)
        return nothing
    end
    @eval function $fname!(p::PlotObject, minval::Union{Nothing, Number}, maxval::Union{Nothing, Number}, adjust::Bool=false)
        $fname!(p, (minval, maxval), adjust)
    end
    @eval $fname!(p::PlotObject) = $fname!(p, (nothing, nothing))
    @eval $fname!(f::Figure, args...) = $fname!(currentplot(f), args...)
    @eval @doc AXISLIM_DOC function $fname(args...)
        f = gcf()
        $fname!(currentplot(f), args...)
        draw(f)
    end

    # xlog, xflip, etc.
    for (attr, docstr) ∈ ((:log, :AXISLOG_DOC), (:flip, :AXISFLIP_DOC))
        fname! = Symbol(ax, attr, :!)
        fname = Symbol(ax, attr)
        @eval function $fname!(p::PlotObject, flag=false)
            if p.axes.kind ∈ (:axes2d, :axes3d)
                p.axes.options[:scale] = set_scale(; p.attributes...)
            end
            p.attributes[Symbol($ax, $attr)] = flag
            return nothing
        end
        @eval $fname!(f::Figure, args...) = $fname!(currentplot(f), args...)
        @eval @doc $docstr function $fname(args...)
            f = gcf()
            $fname!(currentplot(f), args...)
            draw(f)
        end
    end
end

const TICKLABELS_DOC = """
    xticklabels(f)
    yticklabels(f)

Customize the string of the X and Y axes tick labels.

The labels of the tick axis can be defined by a function
with one argument (the numeric value of the tick position) that
returns a string, or by an array of strings that are located
sequentially at X = 1, 2, etc.

Use the keyword argument `xticklabels=s`, etc. in plotting functions, to
set the axis tick labels during the creation of plots.

# Examples

```julia
# Label the range (0-1) of the Y-axis as percent values
yticklabels(p -> Base.Printf.@sprintf("%0.0f%%", 100p))
# Label the X-axis with a sequence of strings
xticklabels(["first", "second", "third"])
```
"""

for ax = ("x", "y")
    fname! = Symbol(ax, :ticklabels!)
    fname = Symbol(ax, :ticklabels)
    @eval function $fname!(p::PlotObject, s)
        set_ticklabels!(p.axes.ticklabels; $fname = s)
        p.attributes[Symbol($ax, :ticklabels)] = s
    end
    @eval $fname!(f::Figure, s) = $fname!(currentplot(f), s)
    @eval @doc TICKLABELS_DOC function $fname(s)
        f = gcf()
        $fname!(currentplot(f), s)
        draw(f)
    end
end

# Grid
function grid!(p::PlotObject, flag)
    p.axes.options[:grid] = Int(flag)
    p.attributes[:grid] = flag
end

grid!(f::Figure, flag) = grid!(currentplot(f), flag)

"""
    grid(flag::Bool)

Draw or disable the grid of the current plot axes.

Use the keyword argument `grid=<true/false>`, etc. in plotting functions, to
set the grid during the creation of plots.
"""
function grid(flag)
    f = gcf()
    grid!(currentplot(f), flag)
    draw(f)
end

# Colorbar
colorbar!(p::PlotObject, flag::Bool) = (p.attributes[:colorbar] = flag)

function colorbar!(p::PlotObject, levels::Integer)
    p.colorbar = Colorbar(p.axes, levels)
    colorbar!(p, true)
end

colorbar!(f::Figure, flag) = colorbar!(currentplot(f), flag)

"""
    colorbar(flag::Bool)
    colorbar(levels::Integer)

Set the color bar of the current plot.

The input argument can be a `Bool` (`true` or `false`) to show or hide
the colorbar -- if it is available, or an `Integer` to set the number
of levels shown in the color bar (256 levels by default).

Color bars are only presented when there is actual color data in the plot,
regardless of the usage of this function.

Use the keyword argument `colorbar=<true/false>`, etc. in plotting functions, to
enable or disable the color bar during the creation of plots.
"""
function colorbar(flag)
    f = gcf()
    colorbar!(currentplot(f), flag)
    draw(f)
end

# Aspect ratio
function aspectratio!(p::PlotObject, r)
    margins = plotmargins(p.legend, p.colorbar; p.attributes...)
    set_ratio!(p.viewport.inner, r, margins)
    p.attributes[:ratio] = r
end

aspectratio!(f::Figure, r) = aspectratio!(currentplot(f), r)

"""
    aspectratio(r)

Set the aspect of the current plot to a given width : height ratio.

Use the keyword argument `aspectratio=r`, etc. in plotting functions, to
set the aspect ratio during the creation of plots.

# Examples

```julia
$(_example("aspectratio"))
```
"""
function aspectratio(r)
    f = gcf()
    aspectratio!(currentplot(f), r)
    draw(f)
end

# Radians in polar axes

function radians!(p::PlotObject, flag)
    if p.axes.kind ≠ :polar
        return nothing
    end
    p.axes.options[:radians] = Int(flag)
    p.attributes[:radians] = flag
end

radians!(f::Figure, flag) = radians!(currentplot(f), flag)

"""
    radians(flag::Bool)

Set the scale of angles in polar plots.

Use `radians(true)` to represent angles in radians (default setting),
and `radians(false)` to represent them in degrees.

This operation only modifies the guides of the polar plot grid lines.
The existing geometries are left without changes

Use the keyword argument `radians=<true/false>`, etc. in plotting functions, to
set the scale of angles during the creation of polar plots.

# Example

```julia
# Example data
θ = LinRange(0, 2π, 40)
r = sin.(θ)
# Draw the polar plot (by default in radians)
polar(θ, r)
# Change the angula scale
radians(false)
```
"""
function radians(flag)
    f = gcf()
    radians!(currentplot(f), flag)
    draw(f)
end

# Pan and zoom

function panzoom!(p::PlotObject, x, y, r = 0.0)
    GR.savestate()
    GR.setviewport(p.viewport.inner...)
    GR.setwindow(p.axes.ranges[:x]..., p.axes.ranges[:y]...)
    xmin, xmax, ymin, ymax = GR.panzoom(x, y, r)
    GR.restorestate()
    xlim!(p, (xmin, xmax))
    ylim!(p, (ymin, ymax))
    return nothing
end

panzoom!(f::Figure, args...) = panzoom!(currentplot(f), args...)

"""
    panzoom(x, y[, s = 0])

Pan/zoom the axes of the current plot.

The focus of the zoom is set at a point with an offset of `(x, y)` units
in normalized device coordinates (NDC) from the center of the current axes.
The corners of the axes are linearly displaced towards that point,
such that the size of the new axes is `s` times their original size.

If `s` is set to 0 (the default value), the center of the axes
is displaced at the focus, without resizing-

# Example

```julia
# Move the center 1 unit right and 0.2 up (NDC)
panzoom(1, 0.2)
# Reduce the focus of the axes to half their size
# focusing on the previous point
panzoom(1, 0.2, 0.5)
```
"""
function panzoom(args...)
    f = gcf()
    panzoom!(currentplot(f), args...)
    draw(f)
end

"""
    zoom(s)

Zoom the current axes to the ratio indicated by `s`.

The "zoomed" axes are centered around the same point,
but proportionally resized to `s` times the original size.

# Examples

```julia
# Reduce the axes to half their size
zoom(0.5)
```
"""
zoom(r) = panzoom(0.0, 0.0, r)
zoom!(pf, r) = panzoom!(pf, 0.0, 0.0, r)

const LOCATIONS = Dict( k => i-1 for (i, k) in enumerate((
    "none", "upper right", "upper left", "lower left", "lower right",
    "right", "center left", "center right", "lower center", "upper center", "center",
    "outer upper right", "outer center right", "outer lower right"
)))

# Legend
function legend!(p::PlotObject, args...; location=1, kinds=Tuple{}(), kwargs...)
    location = lookup(location, LOCATIONS)
    # Reset main viewport if there was a legend
    if haskey(p.attributes, :location) && p.attributes[:location] ∈ LEGEND_LOCATIONS[:right_out]
        p.viewport.inner[2] += p.legend.size[1]
    end
    chosen = choosegeoms(p, kinds)
    for i = 1:min(length(args), length(chosen))
        j = chosen[i]
        p.geoms[j] = Geometry(p.geoms[j], label=args[i])
    end
    maxrows = Int(get(kwargs, :maxrows, length(p.geoms)))
    p.legend = Legend(p.geoms, p.viewport.inner, maxrows)
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
in the same order as they were created. The assignment can be
restricted to specific kinds of geometries through the keyword argument
`kinds`, which can take a `Symbol` or a collection of `Symbol`s
that identify the kinds. Use the helper function [`geometrykinds`](@ref)
to see the list of kinds available in the current plot.

Only geometries with non-empty labels and an available guide for legends
will be presented in the legend.

# Examples

```julia
# Set the legends to "a" and "b"
legend("a", "b")
```
"""
function legend(args::AbstractString...; kwargs...)
    f = gcf()
    legend!(currentplot(f), args...; kwargs...)
    return f
end

"""
    geometrykinds([p])

Return a list with symbols that represent the kind
of the geometries included in the given plot or figure `p`.

If no argument is given, it takes the current plot of
the current figure.

# Examples

```julia
julia> # Plot a set of points at values `(x, y)`
julia> # and a regression line passing through `(x, ŷ)`
julia> scatter(x, y)
julia> plot(x, ŷ)
julia> geometrykinds()
2-element Array{Symbol,1}:
 :scatter
 :line
```
"""
geometrykinds(p::PlotObject) = [g.kind for g in p.geoms]
geometrykinds(f::Figure=gcf()) = geometrykinds(currentplot(f))

function choosegeoms(p::PlotObject, kinds=Tuple{}())
    isempty(kinds) && return collect(1:length(p.geoms))
    gk = geometrykinds(p)
    findall(k -> k ∈ kinds, gk)
end

choosegeoms(p::PlotObject, kinds::Symbol) = choosegeoms(p, (kinds,))

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
    return f
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
set the axis limits during the creation of plots.

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
    xlog(flag)
    ylog(flag)
    zlog(flag)

Set the X-, Y- or Z-axis to be drawn in logarithmic scale (`flag == true`),
or in linear scale (`flag == false`).

Use the keyword argument `xlog=<true/false>`, etc. in plotting functions, to
set the logarithmic axes during the creation of plots.

!!! note

    When the axis is set to logarithmic scale, its lower limit is adjusted
    to represent only positive values, even if the data of the plot contain
    zero or negative values. The aspect of logarithmic axes with limits
    explicitly set to contain negative values (with [`xlim`](@ref), etc.)
    is undefined.

# Examples

```julia
# Set the x-axis limits to log scale
xlog(true)
# Ensure that the y-axis is in linear scale
ylog(false)
```
"""

const AXISFLIP_DOC = """
    xflip(flag)
    yflip(flag)
    zflip(flag)

Reverse the direction of the X-, Y- or Z-axis (`flag == true`),
or set them back to their normal direction (`flag == false` ).

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

@eval function _config_axislimits!(ax, p, (minval, maxval), adjust)
    data_limits = minmax(p.geoms, p.axes.options[:scale])[ax]
    limits = set_limits((minval, maxval), data_limits)
    adjust && (limits = GR.adjustlimits(limits...))
    p.axes.ranges[ax] = limits
    tickdata = p.axes.tickdata
    if haskey(tickdata, ax)
        axisticks = tickdata[ax]
        if get(p.attributes, Symbol(ax,:flip), false)
            limits = reverse(limits)
        end
        tickdata[ax] = (axisticks[1], limits, axisticks[3])
    end
    return nothing
end

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
        return f
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
        return f
    end

    # xlim, etc.
    fname! = Symbol(ax, :lim!)
    fname = Symbol(ax, :lim)
    @eval function $fname!(p::PlotObject, limits, adjust=false)
        _config_axislimits!(Symbol($ax), p, limits, adjust)
        p.attributes[Symbol($ax, :lim)] = limits
    end
    @eval function $fname!(p::PlotObject, minval::Union{Nothing, Number}, maxval::Union{Nothing, Number}, adjust=false)
        $fname!(p, (minval, maxval), adjust)
    end
    @eval $fname!(p::PlotObject) = $fname!(p, (nothing, nothing))
    @eval $fname!(f::Figure, args...) = $fname!(currentplot(f), args...)
    @eval @doc AXISLIM_DOC function $fname(args...)
        f = gcf()
        $fname!(currentplot(f), args...)
        return f
    end

    # xlog, xflip, etc.
    for (attr, docstr) ∈ (("log", :AXISLOG_DOC), ("flip", :AXISFLIP_DOC))
        fname! = Symbol(ax, attr, :!)
        fname = Symbol(ax, attr)
        @eval function $fname!(p::PlotObject, flag)
            if p.axes.kind ∈ (:axes2d, :axes3d)
                p.attributes[Symbol($ax, $attr)] = flag
                newscale = set_scale(; p.attributes...)
                if p.axes.options[:scale] != newscale
                    p.axes.options[:scale] = newscale
                    axlimits = get(p.attributes, Symbol($ax, :lim), (nothing, nothing))
                    adjust = !get(p.attributes, Symbol($ax, :log), false)
                    _config_axislimits!(Symbol($ax), p, axlimits, adjust)
                end
            end
            return nothing
        end
        @eval $fname!(f::Figure, args...) = $fname!(currentplot(f), args...)
        @eval @doc $docstr function $fname(args...)
            f = gcf()
            $fname!(currentplot(f), args...)
            return f
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
        return f
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
    return f
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
    return f
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
    return f
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
    return f
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
    return f
end

# zoom for axes2d and axes3d with gr3
zoom2d!(p, r) = panzoom!(p, 0.0, 0.0, r)

function zoomgr3!(p::PlotObject, r)
    p.axes.camera[1:3] ./= r
    return nothing
end

function zoom!(p::PlotObject, r)
    if p.axes.kind == :axes2d
        zoom2d!(p, r)
    elseif get(p.axes.options, :gr3, 0) ≠ 0
        zoomgr3!(p, r)
    end
end

zoom!(f::Figure, r) = zoom!(currentplot(f), r)

"""
    zoom(r)

Zoom the plot by the ratio indicated by `r`.

In two-dimensional plots, the "zoomed" axes are centered around the same point,
but proportionally resized to `r` times the original size.

In three-dimensional scenes defined with "camera" settings
(e.g. in [`isosurface`](@ref) plots), the camera distance is divided by `r`.

# Examples

```julia
# Reduce the axes to half their size
zoom(0.5)
```
"""
function zoom(r)
    f = gcf()
    zoom!(currentplot(f), r)
    return f
end

# 3-D perspectives

function viewpoint!(p::PlotObject, rotation, tilt)
    p.axes.perspective .= [rotation, tilt]
    if get(p.axes.options, :gr3, 0) ≠ 0
        distance = norm(view(p.axes.camera, 1:3))
        p.axes.camera .= set_camera(distance, rotation, tilt)
    end
    return nothing
end

viewpoint!(f::Figure, rotation, tilt) = viewpoint!(currentplot(f), rotation, tilt)

"""
    viewpoint(rotation, tilt)

Set the viewpoint of three-dimensional plots.

`rotation` and `tilt` must be integer values that indicate the
"azimuth" and "elevation" angles of the line of sight (in degrees).

If both angles are zero, the plot is viewed in the direction of the Y axis
(i.e. the X-Z plane is seen). Positive `rotation` values mean a
counterclockwise rotation of the line of sight (or a clockwise rotation of the scene)
around the vertical (Z) axis. Positive `tilt` values mean an ascension
of the view point.

# Examples

```julia
# Reset the view to the X-Y plane
# (rotation=0, tilt=90)
viewpoint(0, 90)
```
"""
function viewpoint(rotation, tilt)
    f = gcf()
    viewpoint!(currentplot(f), rotation, tilt)
    return f
end

function rotate!(p::PlotObject, angle)
    p.axes.perspective[1] += angle
    if get(p.axes.options, :gr3, 0) ≠ 0
        _rotate!(view(p.axes.camera, 1:3), angle)
        _rotate!(view(p.axes.camera, 7:9), angle)
    end
    return nothing
end

rotate!(f::Figure, angle) = rotate!(currentfigure(f), angle)

function tilt!(p::PlotObject, angle)
    p.axes.perspective[2] += angle
    if get(p.axes.options, :gr3, 0) ≠ 0
        rotation = p.axes.perspective[1]
        camera_position = view(p.axes.camera, 1:3)
        _rotate!(camera_position, -rotation)
        _tilt!(camera_position, angle)
        _rotate!(camera_position, rotation)
        up_vector = view(p.axes.camera, 7:9)
        _rotate!(up_vector, -rotation)
        _tilt!(up_vector, angle)
        _rotate!(up_vector, rotation)
    end
    return nothing
end

tilt!(f::Figure, angle) = tilt!(currentfigure(f), angle)

"""
    rotate(angle::Int)

Rotate the viewpoint of the current plot
by `angle` degrees around the vertical axis of the scene,
with respect to its current position.

# Examples

```julia
# Rotate 10 degrees to the right
rotate(10)
```
"""
function rotate(angle)
    f = gcf()
    rotate!(currentplot(f), angle)
    return f
end

"""
    tilt(angle::Int)

Tilt (elevate) the viewpoint of the current plot
by `angle` degrees over the horizontal plane,
with respect to its current position.

# Examples

```julia
# Tilt 10 degrees up
tilt(10)
```
"""
function tilt(angle)
    f = gcf()
    tilt!(currentplot(f), angle)
    return f
end

# Only for 3-D scenes with gr3

movefocus!(p::PlotObject, target) = _focus!(p.axes.camera, target)
movefocus!(f::Figure, target) = movefocus!(currentplot(f), target)

"""
    movefocus(target)

Rotate the camera view axis, moving the focus to the `target` point.

This only affects 3-D scenes created with camera settings, e.g.
[`isosurface`](@ref) plots. Moving the focus point rotates the camera
without changing its position; in order to rotate the camera around
the center of the scene, use the functions
[`rotate`](@ref), [`tilt`](@ref) or [`viewpoint`](@ref).

# Examples

```julia
# Move the focus to the point (1.0, 0.5, 0.0)
movefocus([1.0, 0.5, 0.0])
```
"""
function movefocus(target)
    f = gcf()
    movefocus!(currentplot(f), target)
    return f
end

function turncamera!(p::PlotObject, angle)
    params = p.axes.camera
    # Rotate up vector towards right vector around axis
    axis = normalize([params[4]-params[1], params[5]-params[2], params[6]-params[3]])
    up_vector = params[7:9]
    right_vector = axis × up_vector
    up_vector .= cosd(angle).*up_vector .+ sind(angle).*right_vector
    return nothing
end

turncamera!(f::Figure, angle) = turncamera!(currentplot(f), angle)

"""
    turncamera(angle)

Turn the orientation of the camera by `angle` degrees
around its view axis (only for 3-D scenes created with camera settings).

# Examples

```julia
# Turn the perspective 10 degrees
turncamera(10)
```
"""
function turncamera(angle)
    f = gcf()
    turncamera!(currentplot(f), angle)
    return f
end


"""
    colormap!(p, cmap)

Apply a colormap `cmap` to the given plot `p`, which can be a `PlotObject`,
or a `Figure` (in such case the colormap is applied to all the plots contained in it).

The value of `cmap` can be the number or the name of any of the
[GR built-in colormaps](https://gr-framework.org/colormaps.html)
(see [`colormap`](@ref) for more details).

Use the keyword argument `colormap` in plotting functions, to set a particular
colormap during the creation of plots (in this case it can only be identified
by its number).

# Examples

```julia
# Create a surface plot with the "grayscale" colormap (2)
surface(x, y, z, colormap=2)
# Change it to the "viridis" colormap
colormap!(gcf(), "viridis")
```
"""
function colormap!(p::PlotObject, cmap)
    p.attributes[:colormap] = Int(cmap)
    return nothing
end

function colormap!(p::PlotObject, cmap::AbstractString)
    cmap = lowercase(replace(cmap, (' ', '_') => ""))
    colormap!(p, COLORMAPS[cmap])
end

function colormap!(f::Figure, cmap)
    for p in f.plots
        colormap!(p, cmap)
    end
    return f
end


"""
    colorscheme!(p, scheme)

Apply a color `scheme` to the given plot `p`, which can be a `PlotObject`,
or a `Figure` (in such case the scheme is applied to all the plots contained in it).

The value of `scheme` can be the number or the name of any available
color scheme (see [`colorscheme`](@ref) for more details).

Use the keyword argument `scheme` in plotting functions, to set a particular
color scheme during the creation of plots (in this case only the number of
an already exisiting scheme is allowed).

# Examples

```julia
# Create a plot with a dark scheme (2)
plot(x, y, scheme=2)
# Change it to the standard light scheme
colorscheme!(currentplot(), "light")
```
"""
function colorscheme!(p::PlotObject, scheme)
    p.attributes[:scheme] = Int(scheme)
    return nothing
end

function colorscheme!(p::PlotObject, scheme::AbstractString)
    scheme = replace(scheme, " " => "")
    scheme = lowercase(scheme)
    scheme_dict = Dict("none" => 0, "light" => 1, "dark" => 2,
        "solarizedlight" => 3, "solarizeddark" => 4)
    colorscheme!(p, scheme_dict[scheme])
end

function colorscheme!(f::Figure, scheme)
    for p in f.plots
        colorscheme!(p, scheme)
    end
    return f
end

# Custom background

"""
    background!(p, bgcolor[, alpha])

Add a custom background color to the given plot object or to all the plots
inside the given figure. See [`background`](@ref) for more details.
"""
function background!(p::PlotObject, bgcolor)
    p.attributes[:backgroundcolor] = Int(bgcolor)
    return nothing
end

function background!(p::PlotObject, bgcolor, alpha)
    p.attributes[:backgroundcolor] = Int(bgcolor)
    p.attributes[:backgroundalpha] = alpha
    return nothing
end

background!(p::PlotObject, ::Nothing) = background!(p, -1)

function background!(f::Figure, args...)
    for p in f.plots
        background!(p, args...)
    end
    return f
end

"""
    background(color[, alpha])

Add a custom background color to the current figure.

The argument can be an hexadecimal color code or `nothing` for a transparent
background. A partially transparent color can be defined adding the alpha
value between 0 and 1 as second argument.

Use the keyword arguments `backgroundcolor` and `backgroundalpha`
in plotting functions, to set a particular background color configuration
during the creation of plots.

This overrides the default background defined by the [`colorscheme`](@ref) for
the area outside the axes and legends of all the plots contained in the figure.
Use [`background!`](@ref) to modify the background of individual subplots.

# Examples
```julia
# Create a plot with light blue background
plot(x, y, backgroundcolor=0x88ccff)
# Remove the background
background(nothing)
```
"""
background(args...) = background!(gcf(), args...)

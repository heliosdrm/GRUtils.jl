"""
    Colorbar(range, tick, scale, margin, colors)

Return a `Colorbar` object containing the data that defines the colorbar
associated to a plot.

The fields contained in a `Legend` object are:

* **`range`**: a Tuple{Float64, Float64} with the range of the color scale
    represented in the bar.
* **`tick`**: a `Float64` that gives the distance between tick marks drawn as
    guide next to the bar.
* **`scale`**: an `Int` code used by `GR.setscale` to define the
    scale of the bar (basically, if it is presented as linear or log scale).
* **`margin`**: a `Float64` with the size of the extra margin between the main
    plot frame and the bar.
* **`colors**`: an `Int` indicating the number of different grades in the color scale.
"""
struct Colorbar
    range::Tuple{Float64, Float64}
    tick::Float64
    scale::Int
    margin::Float64
    colors::Int
end

const EMPTYCOLORBAR = Colorbar(NULLPAIR, 0.0, 0, 0.0, 0)
Colorbar() = EMPTYCOLORBAR

"""
    Colorbar(axes::Axes [, colors=256])

Return a `Colorbar` defined by an `Axes` object that is used to calculate
its different properties, depending on the kind of axis and the range of the
`c` axis. If the `c` axis is not defined, this will return an empty `Colorbar`.
"""
function Colorbar(axes, colors=256)
    range = axes.ranges[:c]
    if !all(isfinite.(range))
        return EMPTYCOLORBAR
    end
    # Set the colorbar scale taking into account the scale of the main axes
    axscale = get(axes.options, :scale, 0)
    tick = get(axes.options, :clog, false) ? 2.0 : 0.5 * GR.tick(range...)
    if get(axes.options, :yflip, false)
        scale = axscale & ~GR.OPTION_FLIP_Y & ~GR.OPTION_FLIP_X
    else
        scale = axscale & ~GR.OPTION_FLIP_X
    end
    # Increase margin in 3-D axes (except if seen as a 2-D plane) and in polar axes
    if all(axes.perspective .≠ 0) || axes.kind == :polar
        margin = 0.05
    else
        margin = 0.0
    end
    Colorbar(range, tick, scale, margin, colors)
end

####################
## `draw` methods ##
####################

function draw(cb::Colorbar, crange=cb.range)
    cb == EMPTYCOLORBAR && return nothing
    zmin, zmax = crange
    # Redefine ticks if the range does not coincide with the default
    tick = (crange == cb.range) ? cb.tick : 0.5 * GR.tick(zmin, zmax)
    mainvp = GR.inqviewport()
    _, charheight = _tickcharheight(mainvp)
    GR.savestate()
    GR.setviewport(mainvp[2] + 0.02 + cb.margin, mainvp[2] + 0.05 + cb.margin, mainvp[3], mainvp[4])
    GR.setscale(cb.scale)
    GR.setwindow(0, 1, zmin, zmax)
    # Draw grade of colors
    l = round.(Int32, range(1000, stop=1255, length=cb.colors))
    h = 0.5 * (zmax - zmin) / (cb.colors - 1)
    GR.cellarray(0, 1, zmax, zmin, 1, cb.colors, l)
    GR.cellarray(0, 1, zmax + h, zmin - h, 1, cb.colors, l)
    # Draw ruled box
    GR.setlinecolorind(1)
    GR.setcharheight(charheight)
    GR.axes(0, tick, 1, zmin, 0, 1, 0.005)
    GR.restorestate()
    return nothing
end

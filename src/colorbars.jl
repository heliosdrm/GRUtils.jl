struct Colorbar
    range::Tuple{Float64, Float64}
    tick::Float64
    scale::Int
    margin::Float64
    colors::Int
end

Colorbar() = Colorbar((0.0, 0.0), 0.0, 0, 0.0, 0)

function Colorbar(axes, colors=256)
    range = axes.ranges[:z]
    axscale = get(axes.options, :scale, 0)
    tick = (axscale & GR.OPTION_Z_LOG == 0) ? 0.5 * GR.tick(range...) : 2
    if get(axes.options, :zflip, false)
        scale = (axscale | GR.OPTION_FLIP_Y) & ~GR.OPTION_FLIP_X
    elseif get(axes.options, :yflip, false)
        scale = axscale & ~GR.OPTION_FLIP_Y & ~GR.OPTION_FLIP_X
    else
        scale = axscale & ~GR.OPTION_FLIP_X
    end
    margin = isa(axes, Axes{:axes3d}) ? 0.05 : 0.0
    Colorbar(range, tick, scale, margin, colors)
end

function draw(cb::Colorbar)
    cb.range == (0.0, 0.0) && return nothing
    zmin, zmax = cb.range
    mainvp = GR.inqviewport()
    _, charheight = _tickcharheight(mainvp)
    GR.savestate()
    GR.setviewport(mainvp[2] + 0.02 + cb.margin, mainvp[2] + 0.05 + cb.margin, mainvp[3], mainvp[4])
    GR.setscale(cb.scale)
    GR.setwindow(0, 1, zmin, zmax)
    l = round.(Int32, linspace(1000, 1255, cb.colors))
    GR.cellarray(0, 1, zmax, zmin, 1, cb.colors, l)
    GR.setlinecolorind(1)
    GR.setcharheight(charheight)
    GR.axes(0, cb.tick, 1, zmin, 0, 1, 0.005)
    GR.restorestate()
    return nothing
end

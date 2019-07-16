struct Viewport
    outer::Vector{Float64}
    inner::Vector{Float64}
end

Viewport() = Viewport(zeros(4), zeros(4))

function Viewport(subplot)
    ratio_w, ratio_h = wswindow(gcf())
    outer = [subplot[1]*ratio_w, subplot[2]*ratio_w, subplot[3]*ratio_h, subplot[4]*ratio_h]
    # inner contains the axes
    low, high = 0.375, 0.425
    xcenter = 0.5 * (outer[1] + outer[2])
    ycenter = 0.5 * (outer[3] + outer[4])
    vp_x = outer[2] - outer[1]
    vp_y = outer[4] - outer[3]
    inner = [xcenter - low*vp_x, xcenter + high*vp_x, ycenter - low*vp_y, ycenter + high*vp_y]
    Viewport(outer, inner)
end

function Viewport(subplot, ratio::Real)
    v = Viewport(subplot)
    w = v.inner[2] - v.inner[1]
    h = v.inner[4] - v.inner[3]
    if w/h > ratio
        d = 0.5 * (w - h * ratio)
        v.inner[1] += d
        v.inner[2] -= d
    else
        d = 0.5 * (h - w / ratio)
        v.inner[3] += d
        v.inner[4] -= d
    end
    v
end

"""
(not parametric, just a named tuple)
"""
mutable struct PlotObject
    viewport::Viewport
    axes::Axes
    geoms::Vector{<:Geometry}
    legend::Legend
    colorbar::Colorbar
    specs::Dict
end

function PlotObject(geoms, axes, legend=Legend(), colorbar=Colorbar(); kwargs...)
    subplot = get(kwargs, :subplot, unitsquare)
    if haskey(kwargs, :ratio)
        viewport = Viewport(subplot, kwargs[:ratio])
    elseif isa(axes, Axes{:axes3d}) || isa(axes, Axes{:axespolar})
        viewport = Viewport(subplot, 1.0)
    else
        viewport = Viewport(subplot)
    end
    if get(kwargs, :colorbar, false) && colorbar ≠ emptycolorbar
        viewport.inner[2] -= 0.1
    end
    location = get(kwargs, :location, 0)
    # Redefine viewport if legend is set outside
    if legend ≠ emptylegend && location ∈ legend_locations[:right_out]
        viewport.inner[2] -= legend.size[1]
    end
    PlotObject(viewport, axes, geoms, legend, colorbar; kwargs...)
end

function PlotObject(viewport, axes, geoms, legend, colorbar; kwargs...)
    specs = Dict(:subplot => unitsquare, kwargs...)
    PlotObject(viewport, axes, geoms, legend, colorbar, specs)
end

PlotObject(; kwargs...) = PlotObject(Viewport(), Axes{nothing}(), Geometry[], Legend(), Colorbar(); kwargs...)

# `draw` methods
function draw(p::PlotObject)
    # GR.clearws()
    colorspecs = [get(p.specs, :colormap, GR.COLORMAP_VIRIDIS),
                  get(p.specs, :scheme, 0x00000000)]
    setcolors(colorspecs...)
    haskey(p.specs, :backgroundcolor) && fillbackground(p.viewport.outer, cv.options[:backgroundcolor])
    # Define the viewport
    GR.setviewport(p.viewport.inner...)
    draw(p.axes)
    # title and labels

    GR.uselinespec(" ")
    for g in p.geoms
        draw(g)
    end
    location = get(p.specs, :location, 0)
    draw(p.legend, p.geoms, location)
    get(p.specs, :colorbar, false) && draw(p.colorbar)
    # GR.updatews()
    # GR.show()
end


function setcolors(colormap, scheme)
    GR.setcolormap(colormap)
    scheme == 0 && (return nothing)
    for colorind in 1:8
        color = colors[colorind, scheme]
        if colorind == 1
            background = color
        end
        r, g, b = RGB(color)
        GR.setcolorrep(colorind - 1, r, g, b)
        if scheme != 1
            GR.setcolorrep(distinct_cmap[colorind], r, g, b)
        end
    end
    r, g, b = RGB(colors[1, scheme])
    rdiff, gdiff, bdiff = RGB(colors[2, scheme]) - [r, g, b]
    for colorind in 1:12
        f = (colorind - 1) / 11.0
        GR.setcolorrep(92 - colorind, r + f*rdiff, g + f*gdiff, b + f*bdiff)
    end
    return nothing
end

function fillbackground(rectndc, color)
    GR.savestate()
    GR.selntran(0)
    GR.setfillintstyle(GR.INTSTYLE_SOLID)
    GR.setfillcolorind(color)
    GR.fillrect(rectndc...)
    GR.selntran(1)
    GR.restorestate()
end

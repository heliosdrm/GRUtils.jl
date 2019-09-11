"""
    Viewport(outer::Vector{Float64}, inner::Vector{Float64})
    Viewport(subplot, frame::Bool [, ratio::Real, margins])

The `Viewport` of a plot determines the NDC of the `outer` box that contains
all the elements of the plot, and the `inner` box where the main items
(axes and geometries) are plotted.

A `Viewport` can also be defined by the relative coordinates of the `subplot`
that it refers to, a flag (`frame::Bool`) telling whether there should be a frame
between the outer and inner boxes, and (optionally), the width:height ratio
of the inner box and the extra margins that there should be
between the outer and inner boxes (in the order left-right-bottom-top).
"""
struct Viewport
    outer::Vector{Float64}
    inner::Vector{Float64}
end

const EMPTYVIEWPORT = Viewport(zeros(4), zeros(4))
Viewport() = EMPTYVIEWPORT

function Viewport(subplot, frame::Bool)
    ratio_w, ratio_h = wswindow(gcf())
    outer = [subplot[1]*ratio_w, subplot[2]*ratio_w, subplot[3]*ratio_h, subplot[4]*ratio_h]
    # Basic margins (low = left, bottom; high = right, top)
    low, high = frame ? (0.375, 0.425) : (0.5, 0.5)
    xcenter = 0.5 * (outer[1] + outer[2])
    ycenter = 0.5 * (outer[3] + outer[4])
    vp_x = outer[2] - outer[1]
    vp_y = outer[4] - outer[3]
    inner = [xcenter - low*vp_x, xcenter + high*vp_x, ycenter - low*vp_y, ycenter + high*vp_y]
    Viewport(outer, inner)
end

function Viewport(subplot, frame::Bool, ratio::Real, margins=zeros(4))
    v = Viewport(subplot, frame)
    set_ratio!(v.inner, ratio, margins)
    v
end

function set_ratio!(box, ratio, margins=zeros(4))
    w = box[2] - box[1] - margins[1] - margins[2]
    h = box[4] - box[3] - margins[3] - margins[4]
    if w/h > ratio
        d = 0.5 * (w - h * ratio)
        box[1] += d
        box[2] -= d
    else
        d = 0.5 * (h - w / ratio)
        box[3] += d
        box[4] -= d
    end
    box .-= margins
end

"""
    PlotObject(viewport, axes, geoms, legend, colorbar, attributes)
    PlotObject(viewport, axes, geoms, legend, colorbar; kwargs...)

A `PlotObject` contains the different elements of a plot:

* `viewport`: a [`Viewport`](@ref) object that defines the area covered by the
    plot container and the coordinate axes in the display.
* `axes`: an [`Axes`](@ref) object that defines how to represent the
    coordinate axes of the space where the plot is contained.
* `geoms`: a `Vector` of [`Geometry`](@ref) objects that are plotted in the axes.
* `legend`: a [`Legend`](@ref) object that defines how to present a legend of the
    different geometries (if required).
* `colorbar`: a [`Colorbar`](@ref) object that defines how to present the guide
    to the color scale (if required)
* `attributes`: a dictionary (`Dict{Symbol, Any}`) with varied plot attributes.
    Those specifications can be passed to the `PlotObject` constructor as
    keyword arguments.

### Alternative constructor

    PlotObject(axes, geoms [, legend, colorbar; kwargs...])

The viewport can be ommited in the constructor of a `PlotObject`. In that case,
it will be automatically calculated by the different characteristics of `axes`,
`geoms`, &mdash; and optionally `legend` and `colorbar`, plus the keyword arguments.
If `legend` and `colorbar` are not defined, they are automatically calculated
using the information of `axes`, `geoms` and the keyword arguments.

### Draw method

Plot objects are drawn by the method `draw(::PlotObject)`, which calls other
`draw` methods for its different components. Normally the order that is followed
to draw the plot components is:

1. Paint the background and set the viewport defined by the `viewport` field.
2. Set the window defined by the axes.
3. Draw the axes.
4. Draw the geometries.
5. Draw the legend (if it is not null and `attributes[:location] ≠ 0`).
6. Draw the colorbar (if it is not null and `attributes[:colorbar] == true`).
7. Write different labels and decorations in axes, title, etc.
"""
mutable struct PlotObject
    viewport::Viewport
    axes::Axes
    geoms::Vector{<:Geometry}
    legend::Legend
    colorbar::Colorbar
    attributes::Dict
end

function PlotObject(viewport, axes, geoms, legend, colorbar; kwargs...)
    attributes = Dict(:subplot => UNITSQUARE, kwargs...)
    PlotObject(viewport, axes, geoms, legend, colorbar, attributes)
end

PlotObject(; kwargs...) = PlotObject(Viewport(), Axes(:none), Geometry[], Legend(), Colorbar() ; kwargs...)

function PlotObject(axes::Axes, geoms::Vector{<:Geometry},
    legend::Legend=Legend(geoms), colorbar::Colorbar=Colorbar(axes); kwargs...)

    # Adapt margins to legend and colorbar
    subplot = get(kwargs, :subplot, UNITSQUARE)
    margins = plotmargins(legend, colorbar; kwargs...)
    frame = !get(kwargs, :noframe, false)
    if haskey(kwargs, :ratio)
        viewport = Viewport(subplot, frame, kwargs[:ratio], margins)
    else
        viewport = Viewport(subplot, frame)
        viewport.inner .-= margins
    end
    PlotObject(viewport, axes, geoms, legend, colorbar; kwargs...)
end

"""
    plotmargins(legend, colorbar; kwargs...)

Define the extra margins needed by a given legend and colorbar, taking into
account plot specifications that are given by keyword arguments.
"""
# In this moment only the right margin is affected
function plotmargins(legend, colorbar; kwargs...)
    rightmargin = 0.0
    if get(kwargs, :colorbar, false) && colorbar ≠ EMPTYCOLORBAR
        rightmargin = 0.1
    end
    location = get(kwargs, :location, 0)
    # Redefine viewport if legend is set outside
    if legend ≠ EMPTYLEGEND && location ∈ LEGEND_LOCATIONS[:right_out]
        rightmargin = legend.size[1]
    end
    [0.0, rightmargin, 0.0, 0.0]
end


####################
## `draw` methods ##
####################

"""
    RGB(color)

Return the normalized RGB values (float between 0 and 1) for an integer code
"""
function RGB(color::Integer)
    rgb = zeros(3)
    rgb[1] = float((color >> 16) & 0xff) / 255.0
    rgb[2] = float((color >> 8)  & 0xff) / 255.0
    rgb[3] = float( color        & 0xff) / 255.0
    rgb
end

"""
    setcolors(scheme)

Set the values of discrete color series to a given scheme.
The argument `scheme` must be an integer number between 0 and 4.
"""
function setcolors(scheme)
    scheme == 0 && (return nothing)
    # Take the column for the given scheme
    # and replace the default color indices
    for colorind in 1:8
        color = COLORS[colorind, scheme]
        # if colorind == 1
        #     background = color
        # end
        r, g, b = RGB(color)
        # replace the indices corresponding to "basic colors"
        GR.setcolorrep(colorind - 1, r, g, b)
        # replace also the ones for "distinct colors" (unless for the first index)
        if scheme ≠ 1
            GR.setcolorrep(DISTINCT_CMAP[colorind], r, g, b)
        end
    end
    # Background RGB values
    r, g, b = RGB(COLORS[1, scheme])
    # Difference between foreground and background
    rdiff, gdiff, bdiff = RGB(COLORS[2, scheme]) - [r, g, b]
    # replace the 12 "grey" shades
    for colorind in 1:12
        f = (colorind - 1) / 11.0
        GR.setcolorrep(92 - colorind, r + f*rdiff, g + f*gdiff, b + f*bdiff)
    end
    return nothing
end

"""
Fill the rectangle in given NDC by the given color index
"""
function fillbackground(rectndc, color)
    GR.savestate()
    GR.selntran(0)
    GR.setfillintstyle(GR.INTSTYLE_SOLID)
    GR.setfillcolorind(color)
    GR.fillrect(rectndc...)
    GR.selntran(1)
    GR.restorestate()
end

function draw(p::PlotObject)
    (p.viewport == EMPTYVIEWPORT) && return nothing
    # Set color scals and paint background
    GR.setcolormap(get(p.attributes, :colormap, GR.COLORMAP_VIRIDIS))
    setcolors(get(p.attributes, :scheme, 0))
    inner = p.viewport.inner
    outer = p.viewport.outer
    haskey(p.attributes, :backgroundcolor) && fillbackground(outer, cv.options[:backgroundcolor])
    # Define the viewport
    GR.setviewport(inner...)
    # Draw components of the plot
    draw(p.axes)
    GR.uselinespec(" ")
    # Geometries may include color limits
    colorlimits = Float64[]
    for g in p.geoms
        cl = draw(g)
        append!(colorlimits, cl)
    end
    # Overlay axes if requested
    get(p.attributes, :overlay_axes, false) && draw(p.axes)
    # Legend
    location = get(p.attributes, :location, 0)
    draw(p.legend, p.geoms, location)
    # Colorbar
    if get(p.attributes, :colorbar, false)
        if isempty(colorlimits) || !get(p.attributes, :adjust_colorbar, true)
            draw(p.colorbar)
        else
            draw(p.colorbar, extrema(colorlimits))
        end
    end
    # title and labels
    drawlabels(p)

    return nothing
end

function drawlabels(p)
    inner = p.viewport.inner
    outer = p.viewport.outer
    main = String(get(p.attributes, :title, ""))
    xlabel = String(get(p.attributes, :xlabel, ""))
    ylabel = String(get(p.attributes, :ylabel, ""))
    zlabel = String(get(p.attributes, :zlabel, ""))
    GR.savestate()
    # title
    if !isempty(main)
        GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
        text(0.5 * (inner[1] + inner[2]), outer[4], main)
    end
    # 2d axes
    _, charheight = _tickcharheight()
    if p.axes.kind == :axes2d
        # x
        if !isempty(xlabel)
            GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_BOTTOM)
            text(0.5 * (inner[1] + inner[2]), outer[3] + 0.5 * charheight, xlabel)
        end
        # y
        if !isempty(ylabel)
            GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_TOP)
            GR.setcharup(-1, 0)
            text(outer[1] + 0.5 * charheight, 0.5 * (inner[3] + inner[4]), ylabel)
        end
    # 3d axes
elseif p.axes.kind == :axes3d && (!isempty(xlabel) || !isempty(ylabel) || !isempty(zlabel))
        GR.titles3d(xlabel, ylabel, zlabel)
    end
    GR.restorestate()
end

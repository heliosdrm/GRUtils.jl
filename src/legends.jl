const LEGEND_KINDS = (:line, :line3d, :bar, :errorbar)

const LEGEND_LOCATIONS = Dict(
    :left => [2, 3, 6],
    :center_h => [8, 9, 10],
    :right_out => [11, 12, 13],
    :bottom => [3, 4, 8],
    :center_v => [5, 6, 7, 10, 12]
)

"""
    Legend(size::Tuple{Float64, Float64}, cursors::Vector{Tuple{Float64, Float64}})

Return a `Legend` object.

This type defines the frame where a legend is plotted.
The fields contained in a `Legend` object are a 2-tuple with the size
of the legend box in NDC (width and height, respectively), and a vector of
2-tuples with the positions of the legend items.
"""
struct Legend
    size::Tuple{Float64, Float64}
    cursors::Vector{Tuple{Float64, Float64}}
end

"""
    Legend(geoms, frame [, maxrows])

Return a `Legend` object defined by the collection of geometries that
are meant to be referred to in the legend (`geoms`), and the dimensions
(width, height) of the `frame` in which the legend should be drawn.

The geometries are used to set the number of items to be drawn in the
legend, and their labels. The frame is used to estimate the font size
of the labels.

Optionally, this constructor can take the maximum number of items that
are represented in each column of the legend. Only the items in that collection
of geometries where `label` is not empty will be included.
"""
function Legend(geoms::Array{<:Geometry}, frame, maxrows=length(geoms))
    cursors = Tuple{Float64, Float64}[]
    charsize = charheight(frame)
    row = 0
    x = 0.08         # width reserved for the guide
    y = -0.015       # vertical top margin
    labelwidth = 0.0
    w = h = 0.0      # width and height of the full box
    scale = Int(GR.inqscale())
    # GR.selntran(0)
    GR.setscale(0)
    for g in geoms
        if !isempty(g.label) && g.kind ∈ LEGEND_KINDS
            row += 1
            # New column if the limit is exceeded
            if row > maxrows
                (-y > h) && (h = -y) # increase height if needed
                y = -0.015
                x += labelwidth + 0.08
                labelwidth = 0.0
                row = 1
            end
            sz = stringsize(g.label, charsize)
            (sz[1] > labelwidth) && (labelwidth = sz[1]) # increase label width
            dy = max(sz[2] - 0.03, 0.0) # height of the item
            push!(cursors, (x, y - dy))
            y -= dy + 0.03 # add item height and vertical margin
        end
    end
    GR.setscale(scale)
    # GR.selntran(1)
    if !isempty(cursors)
        # Define width and height
        (-y > h) && (h = -y)
        w = x + labelwidth + 0.015
        return Legend((w, h), cursors)
    else
        return Legend()
    end
end

const EMPTYLEGEND = Legend(NULLPAIR, Tuple{Float64, Float64}[])
Legend() = EMPTYLEGEND

"""
    legend_box(frame, (w, h), location)

Define the rectangle for a legend box, given the main `frame` with respect to
which it is located, the width and height of the box &mdash; in the tuple `(w, h)`,
and the location of the legend &mdash; an integer that defines the location code of
[Matplotlib legends](https://matplotlib.org/3.1.1/api/_as_gen/matplotlib.pyplot.legend.html).

All the values are given in NDC.
"""
function legend_box(frame, (w, h), location)
    if location ∈ LEGEND_LOCATIONS[:right_out]
        px = frame[2] + 0.01
    elseif location ∈ LEGEND_LOCATIONS[:center_h]
        px = 0.5 * (frame[1] + frame[2] - w)
    elseif location ∈ LEGEND_LOCATIONS[:left]
        px = frame[1] + 0.03
    else
        px = frame[2] - 0.03 - w
    end
    if location ∈ LEGEND_LOCATIONS[:center_v]
        py = 0.5 * (frame[3] + frame[4] + h)
    elseif location == 13
        py = frame[3] + h
    elseif location ∈ LEGEND_LOCATIONS[:bottom]
        py = frame[3] + h + 0.03
    elseif location == 11
        py = frame[4]
    else
        py = frame[4] - 0.03
    end
    (px, px + w, py - h, py)
end


####################
## `draw` methods ##
####################

# `location` is an integer code that defines the location of the legend with
# respect to the main plot area &mdash; as defined in
# [Matplotlib legends](https://matplotlib.org/3.1.1/api/_as_gen/matplotlib.pyplot.legend.html).

function draw(lg::Legend, geoms, location=1)
    # Do not draw if the legend is empty or is not meant to be plotted
    (lg == EMPTYLEGEND || location == 0) && return nothing
    # First draw the frame
    GR.savestate()
    # GR.selntran(0)
    viewport = legend_box(GR.inqviewport(), lg.size, location)
    GR.setviewport(viewport...)
    w, h = lg.size
    window = (0, w, -h, 0)
    GR.setwindow(window...)
    GR.setscale(0)
    # Fill rectangle with background color
    GR.setfillintstyle(GR.INTSTYLE_SOLID)
    GR.setfillcolorind(0)
    GR.fillrect(window...)
    # Draw border
    GR.setlinetype(GR.LINETYPE_SOLID)
    GR.setlinecolorind(1)
    GR.setlinewidth(1)
    GR.drawrect(window...)
    # Draw the geometries
    GR.uselinespec(" ")
    GR.settextalign(GR.TEXT_HALIGN_LEFT, GR.TEXT_VALIGN_HALF)
    c = 1
    for g in geoms
        (c > length(lg.cursors)) && break
        cursor = lg.cursors[c]
        if !isempty(g.label) && g.kind ∈ LEGEND_KINDS
            guide(g, cursor[1] - 0.04, cursor[2])
            text(cursor[1], cursor[2], g.label, true)
            c += 1
        else
            GR.uselinespec("")
        end
    end
    resetcolors()
    # GR.selntran(1)
    GR.restorestate()
    return nothing
end

"""
    guide(g, x, y)

Draw a guide to the geometry `g` in the coordinates `x`, `y` of the legend box.

The kind-specific method `guide(::Val{kind}, x, y)` defines the
low-level plotting instructions for the given kind of `g`.
"""
function guide(g::Geometry, x, y)
    GR.savestate()
    GR.settransparency(get(g.attributes, :alpha, 1.0))
    guide(Val(g.kind), g, x, y)
    GR.restorestate()
end

function guide(::Val{:line}, g, x, y)
    mask = _uselinespec(g.spec, g.attributes)
    if hasline(mask)
        GR.setlinewidth(float(get(g.attributes, :linewidth, 1.0)))
        GR.polyline(x .+ [-0.03, 0.03], y .+ [0.0, 0.0])
    end
    if hasmarker(mask)
        GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
        GR.polymarker([x], [y])
    end
    return nothing
end
guide(::Val{:line3d}, args...) = guide(Val(:line), g, x, y)

function guide(::Val{:errorbar}, g, x, y)
    mask = _uselinespec(g.spec, g.attributes)
    if hasline(mask)
        GR.setlinewidth(float(get(g.attributes, :linewidth, 1.0)))
        GR.polyline([x-0.03, x+0.03], [y, y]) # main bar
        GR.polyline([x-0.03, x-0.03], [y-0.01, y+0.01]) # left bar
        GR.polyline([x+0.03, x+0.03], [y-0.01, y+0.01]) # right bar
    end
    if hasmarker(mask)
        GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
        GR.polymarker([x], [y])
    end
    return nothing
end

function guide(::Val{:bar}, g, x, y)
    if haskey(g.attributes, :color)
        colorind = colorindex(Int(g.attributes[:color]))
    else
        ind = get(COLOR_INDICES, :barfill, 0)
        ind = COLOR_INDICES[:barfill] = ind + 1
        colorind = SERIES_COLORS[ind]
    end
    GR.setfillcolorind(colorind)
    GR.setfillintstyle(GR.INTSTYLE_SOLID)
    GR.fillrect(x - 0.03, x + 0.03, y - 0.012, y + 0.012)
    GR.setfillcolorind(1)
    GR.setfillintstyle(GR.INTSTYLE_HOLLOW)
    GR.fillrect(x - 0.03, x + 0.03, y - 0.012, y + 0.012)
end

guide(kind, g, x, y) = nothing

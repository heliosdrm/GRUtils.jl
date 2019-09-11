"""
    Figure(workstation::Tuple{Float64, Float64}, plots::Vector{PlotObject})
    Figure([figsize::Tuple{Float64, Float64}, units::String])

A `Figure` is the defined by the size (width, height) of the `workstation`
where plots are drawn, and a vector of [`PlotObjects`](@ref).

The method `draw(::Figure)` sets the workstation and plots all plots contained
in the figure sequentially.

### Alternative constructor

The usual way of creating a new `Figure` is with the constructor
`Figure(figsize, units)`, where `figsize` is a 2-tuple with the target width and
height of the figure, and `units` a string with the abbreviation of the units in
which those dimensions are given ("px" for pixels, "in" for inches,
"cm" for centimeters or "m" for meters are allowed). The default dimensions
used by `Figure()` with no arguments is 600×450 pixels &mdash; or a
proportional increased size if the detected display resolution is high.

That constructor also sets the "current figure" to the one that has just been
created. See [`gcf`](@ref) for details.
"""
struct Figure
    workstation::Tuple{Float64, Float64}
    plots::Vector{PlotObject}
end

function Figure(figsize=(600,450), units::String="px")
    # Calculate the display resolution (dpi)
    mwidth, mheight, width, height = GR.inqdspsize()
    dpi = width / mwidth * 0.0254
    # Transform figsize to pixels
    sizepx = Tuple(float(s) for s in figsize)
    if units == "px" # keep it as is
    elseif units == "in"
        sizepx = figsize .* dpi
    elseif units == "cm"
        sizepx = figsize .* (dpi / 2.54)
    elseif units == "m"
        sizepx = figsize .* (dpi / 0.0254)
    end
    # increase dimensions if dpi is too big (the figure would be tiny)
    w, h = (dpi > 200) ? Tuple(s * dpi / 100 for s in sizepx) : sizepx
    # Workstation size
    wssize = mwidth / width * w
    ratio = (w > h) ? (1.0, float(h)/w) : (float(w)/h, 1.0)
    workstation = (wssize * ratio[1], wssize * ratio[2])
    plots = [PlotObject()]
    CURRENTFIGURE[] = Figure(workstation, plots)
end

"""
    currentplot([fig::Figure])

Get the "current plot", i.e. the target of the next plotting operations in the
(optionally) given figure `fig`. If no figure is given, the "current figure" is
used (cf. [`gcf`](@ref)).
"""
currentplot(f::Figure=gcf()) = f.plots[end]

# Normalized width and height of a figure'w workstation
wswindow(f::Figure) = f.workstation ./ maximum(f.workstation)

const SUBPLOT_DOC = """
Set current subplot index.

By default, the current plot will cover the whole window. To display more
than one plot, the window can be split into a number of rows and columns,
with the current plot covering one or more cells in the resulting grid.

Subplot indices are one-based and start at the upper left corner, with a
new row starting after every **num_columns** subplots.

:param num_rows: the number of subplot rows
:param num_columns: the number of subplot columns
:param subplot_indices:
	- the subplot index to be used by the current plot
	- a pair of subplot indices, setting which subplots should be covered
	  by the current plot

**Usage examples:**

.. code-block:: julia

    julia> # Set the current plot to the second subplot in a 2x3 grid
    julia> subplot(2, 3, 2)
    julia> # Set the current plot to cover the first two rows of a 4x2 grid
    julia> subplot(4, 2, (1, 4))
    julia> # Use the full window for the current plot
    julia> subplot(1, 1, 1)
"""

@doc SUBPLOT_DOC function subplot!(f::Figure, nr, nc, p, replace=true)
    xmin, xmax, ymin, ymax = 1.0, 0.0, 1.0, 0.0
    for i in collect(p)
        r = nr - div(i-1, nc)
        c = (i-1) % nc + 1
        xmin = min(xmin, (c-1)/nc)
        xmax = max(xmax, c/nc)
        ymin = min(ymin, (r-1)/nr)
        ymax = max(ymax, r/nr)
    end
    coords = [xmin, xmax, ymin, ymax]
    po = PlotObject(; subplot = coords)
    if replace
        po = replaceplot!(f.plots, po)
    end
    push!(f.plots, po)
    return po
end

@doc SUBPLOT_DOC subplot(args...) = subplot!(gcf(), args...)

function replaceplot!(plotcollection, p)
    # If subplot is not specified in p, empty the whole collection
    if !haskey(p.attributes, :subplot)
        empty!(plotcollection)
    else
        coords = p.attributes[:subplot]
        i = 1
        while i ≤ length(plotcollection)
            # Check intersection
            coords_i = get(plotcollection[i].attributes, :subplot, [0.0, 1.0, 0.0, 1.0])
            bottomleft = (max(coords[1], coords_i[1]), max(coords[3], coords_i[3]))
            topright = (min(coords[2], coords_i[2]), min(coords[4], coords_i[4]))
            if all(bottomleft .< topright)
                (coords ≈ coords_i) && (p = plotcollection[i])
                deleteat!(plotcollection, i)
            else
                i += 1
            end
        end
    end
    return p
end

function draw(f::Figure)
    GR.clearws()
    w, h = f.workstation
    GR.setwsviewport(0.0, w, 0.0, h)
    ratio_w, ratio_h = wswindow(f)
    GR.setwswindow(0.0, ratio_w, 0.0, ratio_h)
    for p in f.plots
        draw(p)
    end
    GR.updatews()
    if GR.isinline()
        return GR.show()
    else
        return
    end
end

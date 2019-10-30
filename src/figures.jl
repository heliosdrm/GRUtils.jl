"""
    Figure(workstation::Tuple{Float64, Float64}, plots::Vector{PlotObject})

Return a new figure, defined by:

* **`workstation`**: a `Tuple{Float64, Float64}` with the width and height of the
    overall plot container (workstation), in pixels.
* **`plots`**: a vector of [`PlotObject`](@ref) elements, which contain the information of
    the individual plots included in the figure.
"""
struct Figure
    workstation::Tuple{Float64, Float64}
    plots::Vector{PlotObject}
end

const EMPTYFIGURE = Figure((0.0, 0.0), [PlotObject()])
const CURRENTFIGURE = Ref(EMPTYFIGURE)

"""
    gcf()
    gcf(fig::Figure)

Get the global current figure, or set it to be `fig`.
"""
gcf() = (CURRENTFIGURE[] == EMPTYFIGURE) ? Figure() : CURRENTFIGURE[]
gcf(fig::Figure) = (CURRENTFIGURE[] = fig)

"""
    Figure([figsize::Tuple{Float64, Float64}, units::String])

Create a new figure of a given size.

The figure size is defined by `figsize` (a 2-tuple with the target width and height),
and `units` (a string with the abbreviation of the units: "px" for pixels,
"in" for inches, "cm" for centimeters or "m" for meters).
The default dimensions used by `Figure()` with no arguments is 600×450 pixels
— or a proportional increased size, if the detected display resolution is high.
This constructor also sets the "current figure" to the one that has just been
created..
"""
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

function Base.Multimedia.display(fig::Figure)
    output = draw(fig)
    output isa Nothing && return nothing
    display(output)
    return nothing
end

# Caution! This depends on GR internals
Base.showable(::MIME"image/svg+xml", ::Figure) = GR.mime_type == "svg"
Base.showable(::MIME"image/png", ::Figure) = GR.mime_type == "png"
Base.showable(::MIME"text/html", ::Figure) = GR.mime_type ∈ ("mov", "mp4", "webm")

Base.show(io::IO, mime::M, fig::Figure) where {
    M <: Union{MIME"image/svg+xml", MIME"image/png", MIME"text/html"}
    } = show(io, mime, draw(fig))

"""
    currentplot([fig::Figure])

Get the "current plot", i.e. the target of the next plotting operations in the
(optionally) given figure `fig`.

If no figure is given, the "current figure" is used (cf. [`gcf`](@ref)).
"""
currentplot(f::Figure=gcf()) = f.plots[end]

# Normalized width and height of a figure'w workstation
wswindow(f::Figure) = f.workstation ./ maximum(f.workstation)

## Subplots

function subplot!(f::Figure, nr, nc, p, replace=true)
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

"""
    subplot(num_rows, num_columns, indices[, replace])

Set a subplot in the current figure.

By default, the current plot covers the whole window. To display more
than one plot, the window can be split into a number of rows and columns,
with each plot covering one or more cells in the resulting grid.

Subplot indices are one-based and start at the upper left corner, with a
new row starting after every `num_cols` subplots.

The arguments `num_rows` and `num_cols` indicate the number of rows and columns
of the grid of plots into which the figure is meant to be divided, and `indices`
is an integer or an array of integers that identify a group of cells in that
grid. This function returns a plot with the minimum size that spans over all
those cells, and appends it to the array of plots of the figure,
such that it becomes its current plot.

If the viewport of the new subplot coincides with the viewport of an existing
plot, by default the older one is moved to the first plane, and taken as the
"current plot"; but if there is only a partial overlap between the new subplot
and other plots, the overlapping plots are removed.
To override this behavior and keep all previous plots without changes,
set the optional argument `replace` to false.

# Examples

```julia
$(_example("subplot"))
```
"""
subplot(args...) = subplot!(gcf(), args...)

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
    drawn = false
    for p in f.plots
        drawn = draw(p) || drawn
    end
    GR.updatews()
    if GR.isinline() && drawn
        return GR.show()
    else
        return
    end
end

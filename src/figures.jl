
"""
Figure, just an alias for an array of PlotObjects
"""
struct Figure
    workstation::Tuple{Float64, Float64}
    plots::Vector{<:AbstractPlot}
end

function Figure(sizepx=(600,450); kwargs...)
    # Display size in meters and pixels
    mwidth, mheight, width, height = GR.inqdspsize()
    dpi = width / mwidth * 0.0254
    # w, h: size of the full frame - in pixels
    if haskey(kwargs, :figsize)
        w, h =  (s * dpi for s in figsize)
    else
        w, h = (dpi > 200) ? (s * dpi / 100 for s in sizepx) : sizepx
    end
    # Workstation size
    wssize = mwidth / width * w
    ratio = (w > h) ? (1.0, float(h)/w) : (float(w)/h, 1.0)
    workstation = (wssize * ratio[1], wssize * ratio[2])
    plots = AbstractPlot[PlotObject()]
    currentfigure[] = Figure(workstation, plots)
end

# figure(p=PlotObject()) = Figure([p])

currentplot(f::Figure) = f.plots[end]

wswindow(f::Figure) = f.workstation ./ maximum(f.workstation)

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

subplot(args...) = subplot!(gcf(), args...)

function replaceplot!(plotcollection, p)
    # If subplot is not specified in p, empty the whole collection
    if !haskey(p.specs, :subplot)
        empty!(plotcollection)
    else
        coords = p.specs[:subplot]
        i = 1
        while i ≤ length(plotcollection)
            # Check intersection
            coords_i = get(plotcollection[i].specs, :subplot, [0.0, 1.0, 0.0, 1.0])
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
    GR.show()
end

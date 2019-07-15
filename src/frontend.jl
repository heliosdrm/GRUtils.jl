## Select keyword arguments from list
keys_geom_attributes = [:clabels, :label, :alpha, :linewidth, :markersize, :step_position]
keys_plot_specs = [:where, :subplot, :sizepx, :location, :hold, :horizontal, :nbins, :xflip, :xlog, :yflip, :ylog, :zflip, :zlog,
    :levels, :majorlevels, :color]
# kw_args = [:accelerate, :algorithm, :alpha, :backgroundcolor, :barwidth, :baseline, :clabels, :color, :colormap, :figsize, :isovalue, :labels, :levels, :location, :nbins, :rotation, :size, :tilt, :title, :where, :xflip, :xform, :xlabel, :xlim, :xlog, :yflip, :ylabel, :ylim, :ylog, :zflip, :zlabel, :zlim, :zlog, :clim]

geom_attributes(;kwargs...) = filter(p -> p.first ∈ keys_geom_attributes, kwargs)
plot_specs(;kwargs...) = filter(p -> p.first ∈ keys_plot_specs, kwargs)

_setargs_default(f, args...; kwargs...) = (args, kwargs)

macro plotfunction(fname, options...)
    # Parse options (geom, canvas, and setargs)
    dict_op = Dict{Symbol, Any}(:setargs => _setargs_default)
    for op in options
        if typeof(op) <: Expr && op.head ∈ (:(=), :kw)
            dict_op[op.args[1]] = op.args[2]
        end
    end
    if !haskey(dict_op, :geom)
        throw(ArgumentError("`geom` not specified"))
    end
    if !haskey(dict_op, :canvas)
        throw(ArgumentError("`canvas` not specified"))
    end
    if !haskey(dict_op, :kind)
        dict_op[:kind] = Symbol(fname)
    end
    # Define functions
    fname! = Symbol(fname, :!)
    geom_k = dict_op[:geom]
    canvas_k = dict_op[:canvas]
    plotkind = dict_op[:kind]
    expr = quote
        function $(fname!)(f::Figure, args...; kwargs...)
            p = currentplot(f)
            if haskey(kwargs, :hold)
                holdstate = kwargs[:hold]
            else
                holdstate = get(p.specs, :hold, false)
            end
            if holdstate
                # Keep all specs
                kwargs = (; p.specs..., kwargs...)
                args, kwargs = $(dict_op[:setargs])(f, args...; kwargs...)
                geoms = [p.geoms; geometries(Geometry{$geom_k}, args...; geom_attributes(;kwargs...)...)]
            else
                # Only keep previous subplot
                kwargs = (subplot = p.specs[:subplot], kwargs...)
                args, kwargs = $(dict_op[:setargs])(f, args...; kwargs...)
                geoms = geometries(Geometry{$geom_k}, args...; geom_attributes(;kwargs...)...)
            end
            axes = Axes{$canvas_k}(geoms; kwargs...)
            legend = Legend(geoms)
            colorchannel = get(kwargs, :colorchannel, :none)
            colorbar = Colorbar(axes, colorchannel) # tbd
            p = PlotObject(geoms, axes, legend, colorbar; kind=$plotkind, plot_specs(; kwargs...)...)
            f.plots[end] = p
            draw(f)
        end
        $fname(args...; kwargs...) = $fname!(gcf(), args...; kwargs...)
    end
    # Add docstrings if available
    if haskey(dict_op, :docstring)
        push!(expr.args, quote
            @doc $(dict_op[:docstring]) $fname
            @doc $(dict_op[:docstring]) $fname!
        end)
    end
    esc(expr)
end

const docplot = """
Function for plotting
"""
@plotfunction(plot, geom = :line, canvas = :axes2d, kind = :line, docstring=docplot)

function _setargs_step(f, args...; kwargs...)
    step_position_str = get(kwargs, :where, "mid")
    if step_position_str == "mid"
        step_position = 0.0
    elseif step_position_str == "post"
        step_position = 1.0
    elseif step_position_str == "pre"
        step_position = -1.0
    else
        throw(ArgumentError("""`where` must be one of `"mid"`, `"pre"` or `"post"`"""))
    end
    return (args, (step_position=step_position, where=step_position_str, kwargs...))
end
@plotfunction(step, geom = :step, canvas = :axes2d, setargs=_setargs_step)

@plotfunction(stem, geom = :stem, canvas = :axes2d)
@plotfunction(scatter, geom = :scatter, canvas = :axes2d)

function barcoordinates(heights; barwidth=0.8, baseline=0.0, kwargs...)
    n = length(heights)
    halfw = barwidth/2
    wc = zeros(2n)
    hc  = zeros(2n)
    for (i, value) in enumerate(heights)
        wc[2i-1] = i - halfw
        wc[2i]   = i + halfw
        hc[2i-1] = baseline
        hc[2i]   = value
    end
    (wc, hc)
end

function _setargs_bar(f, labels, heights; kwargs...)
    wc, hc = barcoordinates(heights; kwargs...)
    horizontal = get(kwargs, :horizontal, false)
    if horizontal
        args = (hc, wc)
        tickoptions = (yticks = (1,1), yticklabels = string.(labels))
    else
        args = (wc, hc)
        tickoptions = (xticks = (1,1), xticklabels = string.(labels))
    end
    return (args, (; tickoptions..., kwargs...))
end

function _setargs_bar(f, heights; kwargs...)
    n = length(heights)
    _setargs_bar(f, string.(1:n), heights; kwargs...)
end

@plotfunction(barplot, geom = :bar, canvas = :axes2d, setargs=_setargs_bar)

function hist(x, nbins=0, baseline=0.0)
    if nbins <= 1
        nbins = round(Int, 3.3 * log10(length(x))) + 1
    end

    xmin, xmax = extrema(x)
    edges = linspace(xmin, xmax, nbins + 1)
    counts = zeros(nbins)
    buckets = Int[max(2, min(searchsortedfirst(edges, xᵢ), length(edges)))-1 for xᵢ in x]
    for b in buckets
        counts[b] += 1
    end
    wc = zeros(2nbins)
    hc  = zeros(2nbins)
    for (i, value) in enumerate(counts)
        wc[2i-1] = edges[i]
        wc[2i]   = edges[i+1]
        hc[2i-1] = baseline
        hc[2i]   = value
    end
    (wc, hc)
end

function _setargs_hist(f, x; kwargs...)
    nbins = get(kwargs, :nbins, 0)
    horizontal = get(kwargs, :horizontal, false)
    # Define baseline - 0.0 by default, unless using log scale
    if get(kwargs, :ylog, false) || horizontal && get(kwargs, :xlog, false)
        baseline = 1.0
    else
        baseline = 0.0
    end
    wc, hc = hist(x, nbins, baseline)
    args = horizontal ? (hc, wc) : (wc, hc)
    return (args, kwargs)
end

@plotfunction(histogram, geom = :bar, canvas = :axes2d, kind = :hist, setargs = _setargs_hist)

@plotfunction(plot3, geom = :line3d, canvas = :axes3d)
@plotfunction(polar, geom = :polarline, canvas = :axespolar)
@plotfunction(polarhistogram, geom = :polarbar, canvas = :axespolar, kind = :polarhist, setargs = _setargs_hist)

function _setargs_contour(f, x, y, z, h; kwargs...)
    if length(x) == length(y) == length(z)
        x, y, z = GR.gridit(x[:], y[:], z[:], 200, 200)
    end
    if get(kwargs, :color, true)
        clabels = float(1000 + (get(kwargs, :majorlevels, 0)))
        kwargs = (; colorchannel = :z, clabels = clabels, kwargs...)
    else
        clabels = float(get(kwargs, :majorlevels, 1))
        kwargs = (; clabels = clabels, kwargs...)
    end
    return ((x, y, z, h), kwargs)
end

function _setargs_contour(f, x, y, z; kwargs...)
    (x, y, z, _), kwargs = _setargs_contour(f, x, y, z, []; kwargs...)
    levels = Int(get(kwargs, :levels, 0))
    zmin, zmax = get(kwargs, :zlim, (_min(z), _max(z)))
    hmin, hmax = GR.adjustrange(zmin, zmax)
    h = linspace(hmin, hmax, levels == 0 ? 21 : levels + 1)
    return ((x, y, z, h), kwargs)
end

function _setargs_contour(f, x, y, fz::Function, args...; kwargs...)
    z = fz.(x, y)
    _setargs_contour(f, x, y, z, args...; kwargs...)
end

@plotfunction(contour, geom = :contour, canvas = :xyplane, kind = :contour, setargs = _setargs_contour)


function legend!(p::PlotObject, args...; location=1)
    # Reset main viewport if there was a legend
    if haskey(p.specs, :location) && p.specs[:location] ∈ legend_locations[:right_out]
        p.viewport.inner[2] += p.legend.size[1]
    end
    for i = 1:min(length(args), length(p.geoms))
        p.geoms[i] = Geometry(p.geoms[i], label=args[i])
    end
    p.legend = Legend(p.geoms)
    # Redefine viewport if legend is set outside
    if p.legend.size ≠ nullpair && location ∈ legend_locations[:right_out]
        p.viewport.inner[2] -= p.legend.size[1]
    end
    p.specs[:location] = location
end

legend!(f::Figure, args...; kwargs...) = legend!(currentplot(f), args...; kwargs...)
legend(args::AbstractString...; kwargs...) = legend!(gcf(), args...; kwargs...)

hold!(p::PlotObject, state::Bool) = (p.specs[:hold] = state)
hold!(f::Figure, state) = hold!(currentplot(f), state)
hold(state) = hold!(gcf(), state)

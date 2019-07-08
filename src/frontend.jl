## Select keyword arguments from list
keys_geom_attributes = [:label, :alpha, :linewidth, :markersize, :step_position]
keys_plot_specs = [:where, :subplot, :sizepx, :location, :hold, :horizontal, :nbins]
# kw_args = [:accelerate, :algorithm, :alpha, :backgroundcolor, :barwidth, :baseline, :clabels, :color, :colormap, :figsize, :isovalue, :labels, :levels, :location, :nbins, :rotation, :size, :tilt, :title, :where, :xflip, :xform, :xlabel, :xlim, :xlog, :yflip, :ylabel, :ylim, :ylog, :zflip, :zlabel, :zlim, :zlog, :clim]

geom_attributes(;kwargs...) = filter(p -> p.first ∈ keys_geom_attributes, kwargs)
plot_specs(;kwargs...) = filter(p -> p.first ∈ keys_plot_specs, kwargs)

_setargs_default(f, args...; kwargs...) = (args, (currentplot(f).specs..., kwargs...))

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
            args, kwargs = $(dict_op[:setargs])(f, args...; kwargs...)
            p = f.plots[end]
            mergedspecs = plot_specs(; p.specs..., kwargs...)
            holdstate = get(mergedspecs, :hold, false)
            if holdstate
                geoms = [p.geoms; geometries(Geometry{$geom_k}, args...; geom_attributes(;kwargs...)...)]
                specs = mergedspecs
            else
                geoms = geometries(Geometry{$geom_k}, args...; geom_attributes(;kwargs...)...)
                specs = plot_specs(; kwargs...)
            end
            axes = Axes{$canvas_k}(geoms; kwargs...)
            legend = Legend(geoms)
            colorbar = Colorbar() # tbd
            p = PlotObject(geoms, axes, legend, colorbar; kind=$plotkind, specs...)
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
    return (args, pairs((step_position=step_position, where=step_position_str, currentplot(f).specs..., kwargs...)))
end
@plotfunction(step, geom = :step, canvas = :axes2d, setargs=_setargs_step)

@plotfunction(stem, geom = :stem, canvas = :axes2d)
@plotfunction(scatter, geom = :scatter, canvas = :axes2d)
@plotfunction(plot3, geom = :line3d, canvas = :axes3d)
@plotfunction(polar, geom = :polarline, canvas = :axespolar)

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
        tickoptions = (:yticks => (1,1), :yticklabels => string.(labels))
    else
        args = (wc, hc)
        tickoptions = (:xticks => (1,1), :xticklabels => string.(labels))
    end
    return (args, (tickoptions..., currentplot(f).specs..., kwargs...))
end

function _setargs_bar(f, heights; kwargs...)
    n = length(heights)
    _setargs_bar(f, string.(1:n), heights; kwargs...)
end

@plotfunction(barplot, geom = :bar, canvas = :axes2d, setargs=_setargs_bar)

function hist(x, nbins=0)
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
    baseline = 0.0 # fix for log scale
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
    wc, hc = hist(x, nbins)
    horizontal = get(kwargs, :horizontal, false)
    args = horizontal ? (hc, wc) : (wc, hc)
    return (args, (currentplot(f).specs..., kwargs...))
end

@plotfunction(histogram, geom = :bar, canvas = :axes2d, kind = :hist, setargs=_setargs_hist)


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

## Select keyword arguments from list
keys_geom_attributes = [:label, :alpha, :linewidth, :markersize, :step_position]
keys_plot_specs = [:where, :subplot, :sizepx, :location, :hold]
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

legend!(f::Figure, args...; kwargs...) = legend!(f.plots[end], args...; kwargs...)
legend(args::AbstractString...; kwargs...) = legend!(gcf(), args...; kwargs...)

hold!(p::PlotObject, state::Bool) = (p.specs[:hold] = state)
hold!(f::Figure, state) = hold!(f.plots[end], state)
hold(state) = hold!(gcf(), state)

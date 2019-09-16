# Legend
function legend!(p::PlotObject, args...; location=1)
    # Reset main viewport if there was a legend
    if haskey(p.attributes, :location) && p.attributes[:location] ∈ LEGEND_LOCATIONS[:right_out]
        p.viewport.inner[2] += p.legend.size[1]
    end
    for i = 1:min(length(args), length(p.geoms))
        p.geoms[i] = Geometry(p.geoms[i], label=args[i])
    end
    p.legend = Legend(p.geoms)
    # Redefine viewport if legend is set outside
    if p.legend.size ≠ NULLPAIR && location ∈ LEGEND_LOCATIONS[:right_out]
        p.viewport.inner[2] -= p.legend.size[1]
    end
    p.attributes[:location] = location
end

legend!(f::Figure, args...; kwargs...) = legend!(currentplot(f), args...; kwargs...)

"""
Set the legend of the plot.

The plot legend is drawn using the extended text function GR.textext.
You can use a subset of LaTeX math syntax, but will need to escape
certain characters, e.g. parentheses. For more information see the
documentation of GR.textext.

:param args: The legend strings

**Usage examples:**

.. code-block:: julia

    julia> # Set the legends to "a" and "b"
    julia> legend("a", "b")
"""
function legend(args::AbstractString...; kwargs...)
    f = gcf()    
    legend!(currentplot(f), args...; kwargs...)
    draw(f)
end

# Hold
hold!(p::PlotObject, state::Bool) = (p.attributes[:hold] = state)

hold!(f::Figure, state) = hold!(currentplot(f), state)

"""
Set the hold flag for combining multiple plots.

The hold flag prevents drawing of axes and clearing of previous plots, so
that the next plot will be drawn on top of the previous one.

:param flag: the value of the hold flag

**Usage examples:**

.. code-block:: julia

    julia> # Create example data
    julia> x = LinRange(0, 1, 100)
    julia> # Draw the first plot
    julia> plot(x, x.^2)
    julia> # Set the hold flag
    julia> hold(true)
    julia> # Draw additional plots
    julia> plot(x, x.^4)
    julia> plot(x, x.^8)
    julia> # Reset the hold flag
    julia> hold(false)
"""
function hold(state)
    f = gcf()    
    hold!(currentplot(f), state)
    draw(f)
end

# Title
function title!(p::PlotObject, s)
    if isempty(s)
        delete!(p.attributes, :title)
    else
        p.attributes[:title] = s
    end
    return nothing
end

title!(f::Figure, s) = title!(currentplot(f), s)

"""
Set the plot title.

The plot title is drawn using the extended text function GR.textext.
You can use a subset of LaTeX math syntax, but will need to escape
certain characters, e.g. parentheses. For more information see the
documentation of GR.textext.

:param title: the plot title

**Usage examples:**

.. code-block:: julia

    julia> # Set the plot title to "Example Plot"
    julia> title("Example Plot")
    julia> # Clear the plot title
    julia> title("")
"""
function title(s::AbstractString)
    f = gcf()    
    title!(currentplot(f), s)
    draw(f)
end

const AXISLABEL_DOC = """
Set the X, Y or Z axis labels.

The axis labels are drawn using the extended text function GR.textext.
You can use a subset of LaTeX math syntax, but will need to escape
certain characters, e.g. parentheses. For more information see the
documentation of GR.textext.

:param label: the axis label

**Usage examples:**

.. code-block:: julia

    julia> # Set the x-axis label to "x"
    julia> xlabel("x")
    julia> # Clear the y-axis label
    julia> ylabel("")
"""

const TICKS_DOC = """
Set the intervals of the ticks for the X, Y or Z axis.

Use the function `xticks`, `yticks` or `zticks` for the corresponding axis.

:param minor: the interval between minor ticks.
:param major: (optional) the number of minor ticks between major ticks.

**Usage examples:**

.. code-block:: julia

    julia> # Minor ticks every 0.2 units in the X axis
    julia> xticks(0.2)
    julia> # Major ticks every 1 unit (5 minor ticks) in the Y axis
    julia> yticks(0.2, 5)
"""

# Attributes for axes

const AXISLIM_DOC = """
Set the limits for the plot axis.

The axis limits can either be passed as individual arguments or as a
tuple of (**min**, **max**). Setting either limit to **nothing** will
cause it to be automatically determined based on the data, which is the
default behavior.

:param min:
	- the axis lower limit, or
	- **nothing** to use an automatic lower limit, or
	- a tuple of both axis limits
:param x_max:
	- the axis upper limit, or
	- **nothing** to use an automatic upper limit, or
	- **nothing** if both axis limits were passed as first argument
:param adjust: whether or not the limits may be adjusted

**Usage examples:**

.. code-block:: julia

    julia> # Set the x-axis limits to -1 and 1
    julia> xlim((-1, 1))
    julia> # Reset the x-axis limits to be determined automatically
    julia> xlim()
    julia> # Set the y-axis upper limit and set the lower limit to 0
    julia> ylim((0, nothing))
    julia> # Reset the y-axis lower limit and set the upper limit to 1
    julia> ylim((nothing, 1))
"""

const AXISLOG_DOC = """
Set the X-, Y- or Z-axis to be drawn in logarithmic scale.

:param flag: the value of the log flag (**false** by default).

**Usage examples:**

.. code-block:: julia

    julia> # Set the x-axis limits to log scale
    julia> xlog(true)
    julia> # Ensure that the y-axis is in linear scale
    julia> ylog(false)
"""

const AXISFLIP_DOC = """
Reverse the direction of the X-, Y- or Z-axis.

:param flag: the value of the flip flag (**false** by default).

**Usage examples:**

.. code-block:: julia

    julia> # Reverse the x-axis
    julia> xflip(true)
    julia> # Ensure that the y-axis is not reversed
    julia> yflip(false)
"""

for ax = ("x", "y", "z")
    # xlabel, etc.
    fname! = Symbol(ax, :label!)
    fname = Symbol(ax, :label)
    @eval function $fname!(p::PlotObject, s)
        if isempty(s)
            delete!(p.attributes, Symbol($ax, :label))
        else
            p.attributes[Symbol($ax, :label)] = s
        end
        return nothing
    end
    @eval $fname!(f::Figure, s) = $fname!(currentplot(f), s)
    @eval @doc AXISLABEL_DOC function $fname(s::AbstractString) 
        f = gcf()
        $fname!(currentplot(f), s)
        draw(f)
    end

    # xticks, etc.
    fname! = Symbol(ax, :ticks!)
    fname = Symbol(ax, :ticks)
    @eval function $fname!(p::PlotObject, minor, major=1)
        tickdata = p.axes.tickdata
        if haskey(tickdata, Symbol($ax))
            tickdata[Symbol($ax)] = (float(minor), tickdata[Symbol($ax)][2], Int(major))
        end
        p.attributes[Symbol($ax, :ticks)] = (minor, major)
        return nothing
    end
    @eval $fname!(f::Figure, args...) = $fname!(currentplot(f), args...)
    @eval @doc TICKS_DOC function $fname(args...)
        f = gcf()
        $fname!(currentplot(f), args...)
        draw(f)
    end

    # xlim, etc.
    fname! = Symbol(ax, :lim!)
    fname = Symbol(ax, :lim)
    @eval function $fname!(p::PlotObject, (minval, maxval), adjust::Bool=false)
        nomin = isa(minval, Nothing)
        nomax = isa(maxval, Nothing)
        fullrange = (nomin || nomax) ? minmax(p.geoms)[Symbol($ax)] : float.((minval, maxval))
        if nomin && !nomax     # (::Nothing, ::Number)
            limits = (fullrange[1], float(maxval))
        elseif !nomin && nomax # (::Number, Nothing)
            limits = (float(minval), fullrange[2])
        else # (::Number, ::Number) or (::Nothing, ::Nothing)
            limits = fullrange
        end
        adjust && (limits = GR.adjustlimits(limits...))
        p.axes.ranges[Symbol($ax)] = limits
        tickdata = p.axes.tickdata
        if haskey(tickdata, Symbol($ax))
            axisticks = tickdata[Symbol($ax)]
            tickdata[Symbol($ax)] = (axisticks[1], limits, axisticks[3])
        end
        p.attributes[Symbol($ax, :lim)] = (minval, maxval)
        return nothing
    end
    @eval function $fname!(p::PlotObject, minval::Union{Nothing, Number}, maxval::Union{Nothing, Number}, adjust::Bool=false)
        $fname!(p, (minval, maxval), adjust)
    end
    @eval $fname!(f::Figure, args...) = $fname!(currentplot(f), args...)
    @eval @doc AXISLIM_DOC function $fname(args...)
        f = gcf()
        $fname!(currentplot(f), args...)
        draw(f)
    end

    # xlog, xflip, etc.
    for (attr, docstr) ∈ ((:log, :AXISLOG_DOC), (:flip, :AXISFLIP_DOC))
        fname! = Symbol(ax, attr, :!)
        fname = Symbol(ax, attr)
        @eval function $fname!(p::PlotObject, flag=false)
            if p.axes.kind ∈ (:axes2d, :axes3d)
                p.axes.options[:scale] = set_scale(; p.attributes...)
            end
            p.attributes[Symbol($ax, $attr)] = flag
            return nothing
        end
        @eval $fname!(f::Figure, args...) = $fname!(currentplot(f), args...)
        @eval @doc $docstr function $fname(args...)
            f = gcf()
            $fname!(currentplot(f), args...)
            draw(f)
        end
    end
end

const TICKLABELS_DOC = """
Customize the string of the X and Y axes tick labels.

The labels of the tick axis can be defined through a function
with one argument (the numeric value of the tick position) and
returns a string, or through an array of strings that are located
sequentially at X = 1, 2, etc.

:param s: function or array of strings that define the tick labels.

**Usage examples:**

.. code-block:: julia

    julia> # Label the range (0-1) of the Y-axis as percent values
    julia> yticklabels(p -> Base.Printf.@sprintf("%0.0f%%", 100p))
    julia> # Label the X-axis with a sequence of strings
    julia> xticklabels(["first", "second", "third"])
"""

for ax = ("x", "y")
    fname! = Symbol(ax, :ticklabels!)
    fname = Symbol(ax, :ticklabels)
    @eval function $fname!(p::PlotObject, s)
        set_ticklabels!(p.axes.ticklabels; $fname = s)
        p.attributes[Symbol($ax, :ticklabels)] = s
    end
    @eval $fname!(f::Figure, s) = $fname!(currentplot(f), s)
    @eval @doc TICKLABELS_DOC function $fname(s)
        f = gcf()
        $fname!(currentplot(f), s)
        draw(f)
    end
end

# Grid
function grid!(p::PlotObject, flag)
    p.axes.options[:grid] = Int(flag)
    p.attributes[:grid] = flag
end

grid!(f::Figure, flag) = grid!(currentplot(f), flag)

"""
Set the flag to draw a grid in the plot axes.

:param flag: the value of the grid flag (`true` by default)

**Usage examples:**

.. code-block:: julia

    julia> # Hid the grid on the next plot
    julia> grid(false)
    julia> # Restore the grid
    julia> grid(true)
"""
function grid(flag)
    f = gcf()    
    grid!(currentplot(f), flag)
    draw(f)
end

# Colorbar
colorbar!(p::PlotObject, flag) = (p.attributes[:colorbar] = flag)

colorbar!(f::Figure, flag) = colorbar!(currentplot(f), flag)

"""
Set the flag to print a color bar if available

:param flag: the value of the flag

**Usage examples:**

.. code-block:: julia

    julia> colorbar(true)
"""
function colorbar(flag)
    f = gcf()    
    colorbar!(currentplot(f), flag)
    draw(f)
end

# Aspect ratio
function aspectratio!(p::PlotObject, r)
    margins = plotmargins(p.legend, p.colorbar; p.attributes...)
    set_ratio!(p.viewport.inner, r, margins)
    p.attributes[:ratio] = r
end

aspectratio!(f::Figure, r) = aspectratio!(currentplot(f), r)

"""
Set the aspect ratio of the plot

:param r: width:height ratio

**Usage examples:**

.. code-block:: julia

    julia> aspectratio(16/9) # Panoramic ratio
"""
function aspectratio(r)
    f = gcf()    
    aspectratio!(currentplot(f), r)
    draw(f)
end


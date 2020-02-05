"""
    Geometry(kind, x, y, z, c, spec, label, attributes)

Return a `Geometry` containing the data represented in a plot
by means of geometric elements (lines, markers, shapes, etc.).

Each `Geometry` has a `kind`, given by a `Symbol` with the name of the
geometric element that it represents, such as `:line` for lines, `:scatter` for
scattered points, `:bar` for bars, etc. In addition it has the following fields:

* **`x`**, **`y`**, **`z`**, **`c`**: Vectors of `Float64` numbers that are mapped to different
    characteristics of the geometry. `x` and `y` are normally their X and Y
    coordinates; `z` usually is its Z coordinate in 3-D plots, or another
    aesthetic feature (e.g. the size in scatter plots); `c` is usually meant
    to represent the color scale, if it exists.
* **`spec`**: a `String` with the specification of the line style, the type of marker
    and the color of lines in line plots.
    (Cf. the defintion of format strings in [matplotlib](https://matplotlib.org/3.1.1/api/_as_gen/matplotlib.pyplot.plot.html))
* **`label`**: a `String` with the label used to identify the geometry in the plot legend.
* **`attributes`**: a `Dict{Symbol, Float64}` with extra attributes to control how
    geometries are plotted.
"""
struct Geometry
    kind::Symbol
    x::Vector{Float64}
    y::Vector{Float64}
    z::Vector{Float64}
    c::Vector{Float64}
    spec::String
    label::String
    attributes::Dict{Symbol,Float64}
end

emptyvector(T::DataType) = Array{T,1}(undef,0)

"""
    Geometry(kind::Symbol [; kwargs...])

Return a `Geometry` with selected parameters given by keyword arguments.

Most geometries do not need data for all the possible parameters that the
`Geometry` type accepts. Thus, to simplify the creation of geometries, an
alternative constructor takes the geometry’s `kind` as the only positional
argument, and the rest of fields are given as keyword arguments
(empty by default).
"""
Geometry(kind::Symbol;
    x=emptyvector(Float64),
    y=emptyvector(Float64),
    z=emptyvector(Float64),
    c=emptyvector(Float64),
    spec="",
    label="",
    kwargs...) where K =
    Geometry(kind, x, y, z, c, spec, label, Dict{Symbol,Float64}(kwargs...))

"""
    Geometry(g::Geometry; kwargs...)

Return a copy of `g` replacing the data and attributes given as
keyword arguments.
"""
function Geometry(g::Geometry; kwargs...)
    kwargs = (; g.attributes..., kwargs...)
    Geometry(g.kind; x=g.x, y=g.y, z=g.z, c=g.c, spec=g.spec, label=g.label, kwargs...)
end

"""
    geometries(kind, x [, y, z, c; kwargs...]) -> Vector{Geometry}

Create a vector of [`Geometry`](@ref) objects of a given `kind`, from arrays of
data that define the coordinates of the geometries. All the other parameters
of the geometries are given as keyword arguments

This function accepts coordinates defined only by one array of numbers,
by two variables (`x` and `y`, typically for 2-D plots), three (`x`, `y`, `z`)
or all four variables (`x`, `y`, `z` and `c`).
If there is only one array `x` of real numbers given for the geometry coordinates,
they will actually be used as Y coordinates, and X will be defined as a sequence
of integers starting at 1. If that array contains complex numbers, the real part
will be taken as X coordinates, and the imaginary part as Y coordinates.

The coordinates can be given as vectors or matrices with the same number of rows.
In the latter case, each column of the matrices will be used to define a different
`Geometry`. If some coordinates are given as vectors while other are in matrices,
vectors will be recycled in all the geometries.
E.g. if `x` is a vector with N numbers and `y` a matrix with N rows and M columns,
the result will be a M-vector of geometries `g` such that `g[i]` will be a
geometry whose X coordinates are the vector `x`, and whose Y coordinates are the
`i`-th column of `y`.

In addition, the last coordinate can be given as a "broadcastable" function that
takes the previous coordinates as inputs.
"""
geometries(kind, x::AbstractVecOrMat{<:Complex}, args...; kwargs...) =
    geometries(kind, real.(x), imag.(x), args...; kwargs...)

geometries(kind, x::AbstractVecOrMat{<:Real}, f::Function, args...; kwargs...) =
    geometries(kind, x, f.(x), args...; kwargs...)

geometries(kind, x::AbstractVecOrMat{<:Real}, y::AbstractVecOrMat{<:Real},
    f::Function, args...; kwargs...) =
    geometries(kind, x, y, f.(x, y), args...; kwargs...)

geometries(kind, x::AbstractVecOrMat{<:Real}, y::AbstractVecOrMat{<:Real}, z::AbstractVecOrMat{<:Real},
    f::Function, args...; kwargs...) =
    geometries(kind, x, y, z, f.(x, y, z), args...; kwargs...)

# Functions with given x, y, z, c.
column(a::Vector, i::Int) = a
column(a::AbstractVector, i::Int) = collect(a)
column(a::AbstractMatrix, i::Int) = a[:,i]

function geometries(kind,
    x::AbstractVecOrMat, y::AbstractVecOrMat, z::AbstractVecOrMat,
    c::AbstractVecOrMat; kwargs...)

    [Geometry(kind; x=column(x,i), y=column(y,i), z=column(z,i), c=column(c,i), kwargs...)
    for i = 1:size(y,2)]
end

function geometries(kind,
    x::AbstractVecOrMat, y::AbstractVecOrMat, z::AbstractVecOrMat;
    kwargs...)

    [Geometry(kind; x=column(x,i), y=column(y,i), z=column(z,i), kwargs...)
    for i = 1:size(y,2)]
end

function geometries(kind, x::AbstractVecOrMat, y::AbstractVecOrMat; kwargs...)
    [Geometry(kind; x=column(x,i), y=column(y,i), kwargs...)
    for i = 1:size(y,2)]
end

function geometries(kind, y::AbstractVecOrMat; kwargs...)
    [Geometry(kind; x=1:size(y,1), y=column(y,i), kwargs...) for i = 1:size(y,2)]
end

####################
## `draw` methods ##
####################

# call specialized methods for the geometry's kind, and return either `nothing`
# or a `Vector{Float64}` with the limits of the color scale - when it is
# calculated by the drawing operation.

function draw(g::Geometry)
    GR.savestate()
    GR.settransparency(get(g.attributes, :alpha, 1.0))
    clims = draw(g, Val(g.kind))
    GR.restorestate()
    isa(clims, Nothing) ? Float64[] :  float(clims)
end

hasline(mask) = ( mask == 0x00 || (mask & 0x01 != 0) )
hasmarker(mask) = ( mask & 0x02 != 0)

draw(g::Geometry, ::Any) = nothing # for unknown kinds

# Extend GR.uselinespec to take into account explicit line or marker colors
function _uselinespec(spec, attributes)
    if haskey(attributes, :linecolor) || haskey(attributes, :markercolor)
        # hack spec to force a color that will be replaced
        spec = isempty(spec) ? "k-" : "k" * spec
        mask = GR.uselinespec(spec)
        if haskey(attributes, :linecolor)
            colorind = colorindex(Int(attributes[:linecolor]))
            GR.setlinecolorind(colorind)
        end
        if haskey(attributes, :markercolor)
            colorind = colorindex(Int(attributes[:markercolor]))
            GR.setmarkercolorind(colorind)
        end
    else
        mask = GR.uselinespec(spec)
    end
    return mask
end

function draw(g::Geometry, ::Val{:line})::Nothing
    mask = _uselinespec(g.spec, g.attributes)
    if hasline(mask)
        GR.setlinewidth(float(get(g.attributes, :linewidth, 1.0)))
        GR.polyline(g.x, g.y)
    end
    if hasmarker(mask)
        GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
        GR.polymarker(g.x, g.y)
    end
    return nothing
end

function draw(g::Geometry, ::Val{:line3d})::Nothing
    mask = _uselinespec(g.spec, g.attributes)
    if hasline(mask)
        GR.setlinewidth(float(get(g.attributes, :linewidth, 1.0)))
        GR.polyline3d(g.x, g.y, g.z)
    end
    if hasmarker(mask)
        GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
        GR.polymarker3d(g.x, g.y, g.z)
    end
    return nothing
end

function draw(g::Geometry, ::Val{:stair})::Nothing
    mask = _uselinespec(g.spec, g.attributes)
    if hasline(mask)
        GR.setlinewidth(float(get(g.attributes, :linewidth, 1.0)))
        n = length(g.x)
        if g.attributes[:stair_position] < 0 # pre
            xs = zeros(2n - 1)
            ys = zeros(2n - 1)
            xs[1] = g.x[1]
            ys[1] = g.y[1]
            for i in 1:n-1
                xs[2i]   = g.x[i]
                xs[2i+1] = g.x[i+1]
                ys[2i]   = g.y[i+1]
                ys[2i+1] = g.y[i+1]
            end
        elseif g.attributes[:stair_position] > 0 # post
            xs = zeros(2n - 1)
            ys = zeros(2n - 1)
            xs[1] = g.x[1]
            ys[1] = g.y[1]
            for i in 1:n-1
                xs[2i]   = g.x[i+1]
                xs[2i+1] = g.x[i+1]
                ys[2i]   = g.y[i]
                ys[2i+1] = g.y[i+1]
            end
        else # middle
            xs = zeros(2n)
            ys = zeros(2n)
            xs[1] = g.x[1]
            for i in 1:n-1
                xs[2i]   = 0.5 * (g.x[i] + g.x[i+1])
                xs[2i+1] = 0.5 * (g.x[i] + g.x[i+1])
                ys[2i-1] = g.y[i]
                ys[2i]   = g.y[i]
            end
            xs[2n]   = g.x[n]
            ys[2n-1] = g.y[n]
            ys[2n]   = g.y[n]
        end
        GR.polyline(xs, ys)
    end
    if hasmarker(mask)
        GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
        GR.polymarker(g.x, g.y)
    end
    return nothing
end

function draw(g::Geometry, ::Val{:stem})::Nothing
    GR.setlinewidth(float(get(g.attributes, :linewidth, 1.0)))
    # Baseline
    GR.polyline(g.x[1:2], g.y[1:2])
    GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
    GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
    _uselinespec(g.spec, g.attributes)
    for i = 3:length(g.y)
        GR.polyline([g.x[i], g.x[i]], [g.y[1], g.y[i]])
        GR.polymarker([g.x[i]], [g.y[i]])
    end
end

function draw(g::Geometry, ::Val{:errorbar})::Nothing
    horizontal = get(g.attributes, :horizontal, 0.0) == 1.0
    mask = _uselinespec(g.spec, g.attributes)
    if hasline(mask)
        GR.setlinewidth(float(get(g.attributes, :linewidth, 1.0)))
        if horizontal
            for i = 2:3:length(g.x)
                GR.polyline([g.x[i-1], g.x[i+1]], [g.y[i], g.y[i]]) # main bar
                GR.polyline([g.x[i-1], g.x[i-1]], [g.y[i-1], g.y[i+1]]) # low bar
                GR.polyline([g.x[i+1], g.x[i+1]], [g.y[i-1], g.y[i+1]]) # high bar
            end
        else
            for i = 2:3:length(g.x)
                GR.polyline([g.x[i], g.x[i]], [g.y[i-1], g.y[i+1]]) # main bar
                GR.polyline([g.x[i-1], g.x[i+1]], [g.y[i-1], g.y[i-1]]) # low bar
                GR.polyline([g.x[i-1], g.x[i+1]], [g.y[i+1], g.y[i+1]]) # high bar
            end
        end
    end
    if hasmarker(mask)
        GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
        GR.polymarker(g.x[2:3:end], g.y[2:3:end])
    end
    return nothing
end

"""
    normalize_color(c, cmin, cmax)

Normalize a color `c` with the range `(cmin, cmax)`
such that 0 ≤ normalize_color(c, cmin, cmax) ≤ 1
"""
function normalize_color(c, cmin, cmax)
    c = clamp(float(c), cmin, cmax) - cmin
    (cmin ≠ cmax) && (c /= cmax - cmin)
    return c
end

function draw(g::Geometry, ::Val{:scatter})::Nothing
    GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
    GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
    if !isempty(g.z) || !isempty(g.c)
        if !isempty(g.c)
            cmin, cmax = extrema(g.c)
            cnorm = map(x -> normalize_color(x, cmin, cmax), g.c)
            cind = Int[round(Int, 1000 + _i * 255) for _i in cnorm]
        end
        for i in 1:length(g.x)
            !isempty(g.z) && GR.setmarkersize(g.z[i] / 100.0)
            !isempty(g.c) && GR.setmarkercolorind(cind[i])
            GR.polymarker([g.x[i]], [g.y[i]])
        end
    else
        GR.polymarker(g.x, g.y)
    end
    return nothing
end

function draw(g::Geometry, ::Val{:scatter3})::Nothing
    GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
    GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
    if !isempty(g.c)
        cmin, cmax = extrema(g.c)
        cnorm = map(x -> normalize_color(x, cmin, cmax), g.c)
        cind = Int[round(Int, 1000 + _i * 255) for _i in cnorm]
        for i in 1:length(g.x)
            GR.setmarkercolorind(cind[i])
            GR.polymarker3d([g.x[i]], [g.y[i]], [g.z[i]])
        end
    else
        GR.polymarker3d(g.x, g.y, g.z)
    end
    return nothing
end

function draw(g::Geometry, ::Val{:bar})::Nothing
    if haskey(g.attributes, :color)
        colorind = colorindex(Int(g.attributes[:color]))
    else
        ind = get(COLOR_INDICES, :barfill, 0)
        ind = COLOR_INDICES[:barfill] = ind + 1
        colorind = SERIES_COLORS[ind]
    end
    for i = 1:2:length(g.x)
        GR.setfillcolorind(colorind)
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        GR.fillrect(g.x[i], g.x[i+1], g.y[i], g.y[i+1])
        GR.setfillcolorind(1)
        GR.setfillintstyle(GR.INTSTYLE_HOLLOW)
        GR.fillrect(g.x[i], g.x[i+1], g.y[i], g.y[i+1])
    end
end

function draw(g::Geometry, ::Val{:polarline})::Nothing
    mask = _uselinespec(g.spec, g.attributes)
    ymax = maximum(abs.(g.y))
    ρ = g.y ./ ymax
    n = length(ρ)
    x = ρ .* cos.(g.x)
    y = ρ .* sin.(g.x)
    if hasline(mask)
        GR.setlinewidth(float(get(g.attributes, :linewidth, 1.0)))
        GR.polyline(x, y)
    end
    if hasmarker(mask)
        GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
        GR.polymarker(x, y)
    end
    return nothing
end

function draw(g::Geometry, ::Val{:polarbar})::Nothing
    ymin, ymax = extrema(g.y)
    ρ = g.y ./ ymax
    θ = g.x
    colorind = get(COLOR_INDICES, :barfill, 0)
    colorind = COLOR_INDICES[:barfill] = colorind + 1
    for i = 1:2:length(ρ)
        GR.setfillcolorind(SERIES_COLORS[colorind])
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        GR.fillarea([ρ[i] * cos(θ[i]), ρ[i] * cos(θ[i+1]), ρ[i+1] * cos(θ[i+1]), ρ[i+1] * cos(θ[i])],
                    [ρ[i] * sin(θ[i]), ρ[i] * sin(θ[i+1]), ρ[i+1] * sin(θ[i+1]), ρ[i+1] * sin(θ[i])])
        GR.setfillcolorind(1)
        GR.setfillintstyle(GR.INTSTYLE_HOLLOW)
        GR.fillarea([ρ[i] * cos(θ[i]), ρ[i] * cos(θ[i+1]), ρ[i+1] * cos(θ[i+1]), ρ[i+1] * cos(θ[i])],
                    [ρ[i] * sin(θ[i]), ρ[i] * sin(θ[i+1]), ρ[i+1] * sin(θ[i+1]), ρ[i+1] * sin(θ[i])])
    end
end

function draw(g::Geometry, ::Val{:polarhist})::Nothing
    ymin, ymax = extrema(g.y)
    ρ = g.y ./ ymax
    θ = g.x * 180/π
    colorind = get(COLOR_INDICES, :barfill, 0)
    colorind = COLOR_INDICES[:barfill] = colorind + 1
    for i = 2:2:length(ρ)
        GR.setfillcolorind(SERIES_COLORS[colorind])
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        GR.fillarc(-ρ[i], ρ[i], -ρ[i], ρ[i], θ[i-1], θ[i])
        GR.setfillcolorind(1)
        GR.setfillintstyle(GR.INTSTYLE_HOLLOW)
        GR.fillarc(-ρ[i], ρ[i], -ρ[i], ρ[i], θ[i-1], θ[i])
    end
end


function draw(g::Geometry, ::Val{:quiver})::Nothing
    mask = _uselinespec(g.spec, g.attributes)
    GR.setlinewidth(float(get(g.attributes, :linewidth, 1.0)))
    headsize = get(g.attributes, :headsize, 1.0)
    n = length(g.x)
    vectorsizes = (g.x[2:2:n] .- g.x[1:2:n]).^2 .+ (g.y[2:2:n] .- g.y[1:2:n]).^2
    maxsize = 2sum(vectorsizes)/n
    for i = 1:2:n-1
        hs = vectorsizes[(i+1)>>1] * headsize / maxsize
        GR.setarrowsize(sqrt(hs))
        GR.drawarrow(g.x[i], g.y[i], g.x[i+1], g.y[i+1])
    end
    if hasmarker(mask)
        GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
        GR.polymarker(view(g.x, 1:2:length(g.x)-1), view(g.y, 1:2:length(g.y)-1))
    end
    return nothing
end

function draw(g::Geometry, ::Val{:quiver3})::Nothing
    mask = _uselinespec(g.spec, g.attributes)
    GR.setlinewidth(float(get(g.attributes, :linewidth, 1.0)))
    for i = 1:2:length(g.x)-1
        GR.polyline3d(g.x[i:i+1], g.y[i:i+1], g.z[i:i+1])
    end
    if hasmarker(mask)
        GR.setmarkersize(2float(get(g.attributes, :markersize, 1.0)))
        GR.polymarker3d(view(g.x, 1:2:length(g.x)-1), view(g.y, 1:2:length(g.y)-1), view(g.z, 1:2:length(g.z)-1))
    end
    return nothing
end

function draw(g::Geometry, ::Val{:contour})::Nothing
    clabels = get(g.attributes, :clabels, 1.0)
    GR.contour(g.x, g.y, g.c, g.z, Int(clabels))
end

function draw(g::Geometry, ::Val{:contourf})::Nothing
    # clabels limited from 0 to 999
    clabels = rem(get(g.attributes, :clabels, 1.0), 1000)
    GR.contourf(g.x, g.y, g.c, g.z, Int(clabels))
end

function draw(g::Geometry, ::Val{:tricont})::Nothing
    GR.tricontour(g.x, g.y, g.z, g.c)
end

function draw(g::Geometry, ::Val{:surface})::Nothing
    if get(g.attributes, :accelerate, 1.0) == 0.0
        GR.surface(g.x, g.y, g.z, GR.OPTION_COLORED_MESH)
    else
        GR.gr3.clear()
        GR.gr3.surface(g.x, g.y, g.z, GR.OPTION_COLORED_MESH)
    end
end

function draw(g::Geometry, ::Val{:wireframe})::Nothing
    meshcolor = haskey(g.attributes, :color) ? colorindex(Int(g.attributes[:color])) : 0
    linecolor = haskey(g.attributes, :linecolor) ? colorindex(Int(g.attributes[:linecolor])) : 1
    GR.setfillcolorind(meshcolor)
    GR.setlinecolorind(linecolor)
    GR.surface(g.x, g.y, g.z, GR.OPTION_FILLED_MESH)
end

function draw(g::Geometry, ::Val{:trisurf})::Nothing
    GR.trisurface(g.x, g.y, g.z)
end

function draw(g::Geometry, ::Val{:hexbin})::Vector{Float64}
    nbins = Int(get(g.attributes, :nbins, 40.0))
    cntmax = GR.hexbin(g.x, g.y, nbins)
    [0.0, cntmax]
end

function draw(g::Geometry, ::Val{:heatmap})::Nothing
    w = length(g.x) - 1
    h = length(g.y) - 1
    # cmap = colormap()
    cmin, cmax = extrema(g.c)
    data = map(x -> normalize_color(x, cmin, cmax), g.c)
    colors = Int[round(Int, 1000 + _i * 255) for _i ∈ data]
    if w == 0 || h == 0
        w = Int(g.x[1])
        h = Int(g.y[1])
        GR.cellarray(0.0, w, h, 0.0, w, h, colors)
    else
        GR.nonuniformcellarray(g.x, g.y, w, h, colors)
    end
    return nothing
end

function draw(g::Geometry, ::Val{:polarheatmap})::Nothing
    w = length(g.x) == 1 ? Int(g.x[1]) : length(g.x) - 1
    h = length(g.y) == 1 ? Int(g.y[1]) : length(g.y) - 1
    cmin, cmax = extrema(g.c)
    data = map(x -> normalize_color(x, cmin, cmax), g.c)
    colors = Int[round(Int, 1000 + _i * 255) for _i ∈ data]
    GR.polarcellarray(0, 0, 0, 360, 0, 1, w, h, colors)
end

function draw(g::Geometry, ::Val{:image})::Nothing
    w = length(g.x)
    h = length(g.y)
    GR.drawimage(0.0, w, 0.0, h, w, h, g.c)
end

function draw(g::Geometry, ::Val{:isosurf})::Nothing
    nx, ny, nz = Int.(g.x)
    isovalue = g.y[1]
    values = UInt16.(reshape(g.z, (nx, ny, nz)))
    if haskey(g.attributes, :color)
        meshcolor = rgb(UInt32(g.attributes[:color]))
    else
        meshcolor = (0, 0.5, 0.8)
    end
    GR.selntran(0)
    GR.gr3.clear()
    mesh = GR.gr3.createisosurfacemesh(values, (2/(nx-1), 2/(ny-1), 2/(nz-1)),
            (-1., -1., -1.),
            round(Int64, isovalue * (2^16-1)))
    GR.gr3.setbackgroundcolor(1, 1, 1, 0)
    GR.gr3.drawmesh(mesh, 1, (0, 0, 0), (0, 0, 1), (0, 1, 0), meshcolor, (1, 1, 1))
    vp = GR.inqviewport()
    GR.gr3.drawimage(vp..., 500, 500, GR.gr3.DRAWABLE_GKS)
    GR.gr3.deletemesh(mesh)
    GR.selntran(1)
end

function draw(g::Geometry, ::Val{:shade})::Nothing
    xform = Int(get(g.attributes, :xform, 5))
    if Bool(g.attributes[:shadelines])
        GR.shadelines(g.x, g.y, xform=xform)
    else
        GR.shadepoints(g.x, g.y, xform=xform)
    end
end

function draw(g::Geometry, ::Val{:volume})::Vector{Float64}
    algorithm = Int(get(g.attributes, :algorithm, 0))
    GR.gr3.clear()
    dims = (Int(g.x[1]), Int(g.y[1]), Int(g.z[1]))
    v = reshape(g.c, dims)
    dmin, dmax = GR.gr3.volume(v, algorithm)
    [dmin, dmax]
end

draw(g::Geometry, ::Val{:text})::Nothing = text(g.x[1], g.y[1], g.label, true)

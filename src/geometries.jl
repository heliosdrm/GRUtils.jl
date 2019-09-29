"""
    Geometry(kind::Symbol [; kwargs...])

`Geometry` is a type of objects that contain the data represented in a plot
by means of geometric elements (lines, markers, shapes, etc.).

Each `Geometry` has a `kind`, given by a `Symbol` with the name of the
geometric element that it represents. The low level instructions to draw a
a geometry of a given kind are defined by the method `draw(::Geometry, ::Val{kind})`.

The usual way of creating a `Geometry` is through a constructor whose only
positional argument is its `kind`, and the rest of fields are given
as keyword arguments (empty by default). Those fields are:

* `x`, `y`, `z`, `c`: Vectors of `Float64` which are mapped to different
    characteristics of the geometry. `x` and `y` are normally their X and Y
    coordinates; `z` usually is its Z coordinate in 3-D plots, or another
    aesthetic feature (e.g. the size in scatter plots); `c` is usually meant
    to represent the color scale, if it exists.
* `spec`: a `String` with the specification of the line style, the type of marker
    and the color of lines in line plots.
    (Cf. the defintion of format strings in [matplotlib](https://matplotlib.org/3.1.1/api/_as_gen/matplotlib.pyplot.plot.html))
* `label`: a `String` with the label used to identify the geometry in the plot legend.
* `attributes`: a `Dict{Symbol, Float64}` with extra attributes to control how
    geometries are plotted.

See also [`geometries`](@ref).

### Note on the return type of `draw(::Geometry [, ::Val])`

The method `draw(::Geometry, ::Val)` should returns `nothing` or a `Vector{Float64}`
with the limits of the color scale &mdash; when it is calculated by the drawing
operation &mdash; e.g. for `draw(::Geometry, ::Val{:hexbin})`.

The generic method `draw(g::Geometry)` calls the kind-specific method for
`g.kind`, and returns the vector with the color limits or an empty vector.
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

Geometry(kind::Symbol;
    x=emptyvector(Float64),
    y=emptyvector(Float64),
    z=emptyvector(Float64),
    c=emptyvector(Float64),
    spec="",
    label="",
    kwargs...) where K =
    Geometry(kind, x, y, z, c, spec, label, Dict{Symbol,Float64}(kwargs...))

function Geometry(g::Geometry; kwargs...)
    kwargs = (; g.attributes..., kwargs...)
    Geometry(g.kind; x=g.x, y=g.y, z=g.z, c=g.c, spec=g.spec, label=g.label, kwargs...)
end

"""
    geometries(kind, x [, y, z, c; kwargs...]) -> Vector{Geometry}

Create a vector of [`Geometry`](@ref) objects of a given `kind`, with
`x`, `y`, `z` and `c` coordinates, and other parameters determined by the
keyword arguments.

If there is only one array `x` of real numbers given for the geometry coordinates,
this will actually be used as Y coordinates, and X will be defined as a sequence
of integers starting at 1. If that array contains complex numbers, the real part
will be taken as X coordinates, and the imaginary part as Y coordinates.

The last coordinate can be given as a function that will take the previous
coordinates as inputs.
"""
# Complex arguments processed as pair of real, imaginary values
geometries(kind, x::AbstractVecOrMat{<:Complex}, args...; kwargs...) =
    geometries(kind, real.(x), imag.(x), args...; kwargs...)

# Parse function arguments
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

function draw(g::Geometry, ::Val{:line})::Nothing
    mask = GR.uselinespec(g.spec)
    hasline(mask) && GR.polyline(g.x, g.y)
    hasmarker(mask) && GR.polymarker(g.x, g.y)
    return nothing
end

function draw(g::Geometry, ::Val{:line3d})::Nothing
    mask = GR.uselinespec(g.spec)
    hasline(mask) && GR.polyline3d(g.x, g.y, g.z)
    hasmarker(mask) && GR.polymarker3d(g.x, g.y, g.z)
    return nothing
end

function draw(g::Geometry, ::Val{:stair})::Nothing
    mask = GR.uselinespec(g.spec)
    if hasline(mask)
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
    hasmarker(mask) && GR.polymarker(g.x, g.y)
    return nothing
end

function draw(g::Geometry, ::Val{:stem})::Nothing
    baseline = Float64(get(g.attributes, :baseline, 0.0))
    GR.setlinecolorind(1)
    GR.polyline([minimum(g.x), maximum(g.x)], [baseline, baseline])
    GR.setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
    GR.uselinespec(g.spec)
    for i = 1:length(g.y)
        GR.polyline([g.x[i], g.x[i]], [baseline, g.y[i]])
        GR.polymarker([g.x[i]], [g.y[i]])
    end
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
    if !isempty(g.z) || !isempty(g.c)
        if !isempty(g.c)
            # cmin, cmax = plt.kvs[:crange]
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
    for i = 1:2:length(g.x)
        GR.setfillcolorind(989)
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        GR.fillrect(g.x[i], g.x[i+1], g.y[i], g.y[i+1])
        GR.setfillcolorind(1)
        GR.setfillintstyle(GR.INTSTYLE_HOLLOW)
        GR.fillrect(g.x[i], g.x[i+1], g.y[i], g.y[i+1])
    end
end

function draw(g::Geometry, ::Val{:polarline})::Nothing
    GR.uselinespec(g.spec)
    ymin, ymax = extrema(g.y)
    ρ = (g.y .- ymin) ./ (ymax .- ymin)
    n = length(ρ)
    x = ρ .* cos.(g.x)
    y = ρ .* sin.(g.x)
    GR.polyline(x, y)
end

function draw(g::Geometry, ::Val{:polarbar})::Nothing
    xmin, xmax = extrema(g.x)
    ymin, ymax = extrema(g.y)
    ρ = g.y ./ ymax
    θ = 2pi .* (g.x .- xmin) ./ (xmax - xmin)
    for i = 1:2:length(ρ)
        GR.setfillcolorind(989)
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        GR.fillarea([ρ[i] * cos(θ[i]), ρ[i] * cos(θ[i+1]), ρ[i+1] * cos(θ[i+1]), ρ[i+1] * cos(θ[i])],
                    [ρ[i] * sin(θ[i]), ρ[i] * sin(θ[i+1]), ρ[i+1] * sin(θ[i+1]), ρ[i+1] * sin(θ[i])])
        GR.setfillcolorind(1)
        GR.setfillintstyle(GR.INTSTYLE_HOLLOW)
        GR.fillarea([ρ[i] * cos(θ[i]), ρ[i] * cos(θ[i+1]), ρ[i+1] * cos(θ[i+1]), ρ[i+1] * cos(θ[i])],
                    [ρ[i] * sin(θ[i]), ρ[i] * sin(θ[i+1]), ρ[i+1] * sin(θ[i+1]), ρ[i+1] * sin(θ[i])])
    end
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
    GR.setfillcolorind(0) # TBD: let choose the color
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
    w = length(g.x)
    h = length(g.y)
    # cmap = colormap()
    cmin, cmax = extrema(g.c)
    data = map(x -> normalize_color(x, cmin, cmax), g.c)
    # rgba = [to_rgba(value, cmap) for value ∈ data]
    # GR.cellarray(0.0, w, h, 0.0, w, h, rgba)
    colors = Int[round(Int, 1000 + _i * 255) for _i ∈ data]
    GR.cellarray(0.0, w, h, 0.0, w, h, colors)
end


function draw(g::Geometry, ::Val{:polarheatmap})::Nothing
    w = length(g.x)
    h = length(g.y)
    # cmap = colormap()
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
    color = (g.c...,)
    GR.selntran(0)
    GR.gr3.clear()
    mesh = GR.gr3.createisosurfacemesh(values, (2/(nx-1), 2/(ny-1), 2/(nz-1)),
            (-1., -1., -1.),
            round(Int64, isovalue * (2^16-1)))
    GR.gr3.setbackgroundcolor(1, 1, 1, 0)
    GR.gr3.drawmesh(mesh, 1, (0, 0, 0), (0, 0, 1), (0, 1, 0), color, (1, 1, 1))
    vp = GR.inqviewport()
    GR.gr3.drawimage(vp..., 500, 500, GR.gr3.DRAWABLE_GKS)
    GR.gr3.deletemesh(mesh)
    GR.selntran(1)
end

function hasnan(a)
    for el in a
        if el === NaN || el === missing
            return true
        end
    end
    false
end

function draw(g::Geometry, ::Val{:shade})::Nothing
    xform = Int(get(g.attributes, :xform, 5))
    if hasnan(g.x)
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

const COLOR_SCHEMES = [
    (0xffffff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0x00ffff, 0xffff00, 0xff00ff),
    (0x282c34, 0xd7dae0, 0xcb4e42, 0x99c27c, 0x85a9fc, 0x5ab6c1, 0xd09a6a, 0xc57bdb),
    (0xfdf6e3, 0x657b83, 0xdc322f, 0x859900, 0x268bd2, 0x2aa198, 0xb58900, 0xd33682),
    (0x002b36, 0x839496, 0xdc322f, 0x859900, 0x268bd2, 0x2aa198, 0xb58900, 0xd33682)
]

const BASIC_COLORS = [ 0, 1, 984, 987, 989, 983, 994, 988 ]

const SERIES_COLORS = [989, 982, 980, 981, 996, 983, 995, 988, 986, 990, 991, 984, 992, 993, 994, 987, 985, 997, 998, 999]

const COLOR_INDICES = Dict{Symbol, Int}(
    :scheme => 0,
    :colormap => GR.COLORMAP_VIRIDIS
)

function resetcolors()
    for k in keys(COLOR_INDICES)
        if k ∉ (:scheme, :colormap)
            COLOR_INDICES[k] = 0
        end
    end
    return nothing
end

# Color codes

"""
    rgb(color)

Return the normalized RGB values (between 0 and 1)
corresponding to a given hexadecimal color value.

# Examples

```jldoctest
julia> GRUtils.rgb(0xff3300)
(1.0, 0.2, 0.0)
```
"""
function rgb(color::Integer)
    r = float((color >> 16) & 0xff) / 255.0
    g = float((color >> 8)  & 0xff) / 255.0
    b = float( color        & 0xff) / 255.0
    return (r, g, b)
end

"""
    color(r, g, b)

Return the hexadecimal integer corresponding to the given RGB values.

# Examples

```jldoctest
julia> GRUtils.color(1, 0.2, 0)
0x00ff3300
```
"""
function color(r, g, b)
    rint = round(UInt32, r * 255)
    gint = round(UInt32, g * 255)
    bint = round(UInt32, b * 255)
    return rint << 16 + gint << 8 + bint
end

"""
    switchbytes(hexcolor::UInt32)

Switch the R and B channels of hexadecimal colors codes.

Use this function to turn a byte-ordered hexadecimal color code (ARGB, little-endian)
into a word-ordered color code (RGBA, big endian) and vice versa.

# Examples

```jldoctest
julia> GRUtils.switchbytes(0xfe12ac34)
0xfe34ac12
```
"""
switchbytes(c::UInt32) = (c & 0xff00ff00) + (c & 0x00ff0000) >> 16 + (c & 0x000000ff) << 16

"""
    colorindex(hexcolor[, byteorder=false])

Define a color given by an hexadecimal code and return its index in GR's color map.

This is a wrapper to `GR.inqcolorfromrgb` for hexadecimal color codes.
By default it considers that RGB values are ordered from the most to the least
significant bytes. If it is a byte-ordered code, set the second argument to `true`.
"""
function colorindex(hexcolor, byteorder=false)::Int
    if byteorder
        hexcolor = switchbytes(hexcolor)
    end
    GR.inqcolorfromrgb(rgb(hexcolor)...)
end

# Colormaps

const COLORMAPS = Dict( k => i-1 for (i, k) in enumerate((
    "uniform", "temperature", "grayscale", "glowing", "rainbowlike",
    "geologic", "greenscale", "cyanscale", "bluescale", "magentascale",
    "redscale", "flame", "brownscale", "pilatus", "autumn", "bone",
    "cool", "copper", "gray", "hot", "hsv", "jet", "pink", "spectral",
    "spring", "summer", "winter", "gistearth", "gistheat", "gistncar",
    "gistrainbow", "giststern", "afmhot", "brg", "bwr", "coolwarm",
    "cmrmap", "cubehelix", "gnuplot", "gnuplot2", "ocean", "rainbow",
    "seismic", "terrain", "viridis", "inferno", "plasma", "magma"
)))

"""
    colormap(cmap)
    colormap([cmap,] T::Type{<:Integer}[, byteorder::Bool=false])

Set or retrieve the values of the current colormap.

Give the identifier `cmap` to set the colormap. This identifier can be
the number or a string with the name of any of the
[GR built-in colormaps](https://gr-framework.org/colormaps.html).

Give an integer data type `T` to return the set of colors defined
in the current colormap, as a vector of hexadecimal color codes.
By default those codes represent the word-ordered RGB values
in a little-endian system. The optional argument `byteorder`
can be set to `true` in order to retrieve the codes as byte-ordered codes.

At least one of the arguments `cmap::Union{Integer, AbstractString}`
or `T::Type{<:Integer}` are required. If `cmap` not given, the previous
colormap is left as current. If `T` is not given, the function returns
`nothing`.

# Examples

```julia
$(_example("colormap"))
```
"""
function colormap(cmap::Integer)
    GR.setcolormap(cmap)
    COLOR_INDICES[:colormap] = cmap
    return nothing
end

function colormap(cmap::AbstractString)
    cmap = lowercase(replace(cmap, (' ', '_') => ""))
    colormap(lookup(cmap, COLORMAPS))
end

function colormap(::Type{T}, byteorder::Bool=false) where {T <: Integer}
    if byteorder
        return [T(GR.inqcolor(i)) for i ∈ 1000:1255]
    else
        return [GR.inqcolor(i) |> UInt32 |> switchbytes |> T for i ∈ 1000:1255]
    end
end

function colormap(cmap::Union{Integer, AbstractString}, T::DataType, args...)
    colormap(cmap)
    colormap(T, args...)
end

"""
    to_rgba(value[, alpha, cmap])

Calculate the hexadecimal color code of a normalized value between 0 and 1
in the current colormap (byte-ordered, big-endian RGBA).

Optionally, the level of the `alpha` channel can be passed as a value
between 0 (transparent) and 1 (opaque), and a custom colormap can be
defined by `cmap` with the corresponding RGB values
(as byte-ordered hexadecimal colors or triplets of normalized float values).
"""
function to_rgba(value, alpha, cmap=colormap(UInt32, true)::Vector{<:Integer})
    isnan(value) && return zero(UInt32)
    color = UInt32(cmap[round(Int, value * 255 + 1)])
    return color + round(UInt32, alpha * 255) << 24
end

function to_rgba(value)
    isnan(value) && return zero(UInt32)
    colormap(UInt32, true)[round(Int, value * 255 + 1)] + 0xff000000
end


# Color schemes

"""
    applycolorscheme(scheme)

Apply the given color scheme, coded as an integer number between 0 and 4.
See [`colorscheme`](@ref) for the values of the color schemes.
"""
function applycolorscheme(scheme)
    scheme == 0 && return nothing
    # Replace the basic color indices
    for colorind in 1:8
        color = COLOR_SCHEMES[scheme][colorind]
        r, g, b = rgb(color)
        # Set 1-8
        GR.setcolorrep(colorind - 1, r, g, b)
        # In set 980-999 (except for the first scheme)
        if scheme ≠ 1
            GR.setcolorrep(BASIC_COLORS[colorind], r, g, b)
        end
    end
    # Background RGB values
    r, g, b = rgb(COLOR_SCHEMES[scheme][1])
    # Difference between foreground and background
    rdiff, gdiff, bdiff = rgb(COLOR_SCHEMES[scheme][2]) .- (r, g, b)
    # replace the 12 "grey" shades
    for (colorind, f) in enumerate(LinRange(1, 0, 12))
        GR.setcolorrep(79 + colorind, r + f*rdiff, g + f*gdiff, b + f*bdiff)
    end
    return nothing
end

"""
    colorscheme(scheme)

Set the color scheme for subsequent plots.

The value of the scheme can be one of the following numbers or strings:

* 0: `"none"`
* 1: `"light"`
* 2: `"dark"`
* 3: `"solarized light"`
* 4: `"solarized dark"`

The scheme applies to all plots that are drawn after calling
`colorscheme`, even if they have been created beforehand.
To apply a particular scheme to some plot or figure, use
[`colorscheme!`](@ref).

If the scheme is `"none"` (`0`), the standard scheme is set, which
is the same as `"light"` (1), except that the default background of the figure
is transparent.

# Examples

```julia
$(_example("colorscheme"))
```
"""
function colorscheme(scheme::Int)
    COLOR_INDICES[:scheme] = scheme
    return nothing
end

function colorscheme(scheme::AbstractString)
    scheme = replace(scheme, " " => "")
    scheme = lowercase(scheme)
    scheme_dict = Dict("none" => 0, "light" => 1, "dark" => 2,
        "solarizedlight" => 3, "solarizeddark" => 4)
    colorscheme(scheme_dict[scheme])
end

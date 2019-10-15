const COLORS = hcat(
    [0xffffff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0x00ffff, 0xffff00, 0xff00ff],
    [0x282c34, 0xd7dae0, 0xcb4e42, 0x99c27c, 0x85a9fc, 0x5ab6c1, 0xd09a6a, 0xc57bdb],
    [0xfdf6e3, 0x657b83, 0xdc322f, 0x859900, 0x268bd2, 0x2aa198, 0xb58900, 0xd33682],
    [0x002b36, 0x839496, 0xdc322f, 0x859900, 0x268bd2, 0x2aa198, 0xb58900, 0xd33682]
)

const DISTINCT_CMAP = [ 0, 1, 984, 987, 989, 983, 994, 988 ]

const COLOR_INDICES = Dict{Symbol, Int}(
    :scheme => 0,
    :background => -1,
    :colormap => GR.COLORMAP_VIRIDIS
)

# Color codes

"""
    rgb(color)

Return the normalized RGB values (between 0 and 1)
corresponding to a given hexadecimal color value.
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

"""
    setcolormap(cmap)

Set the current colormap to one of the built-in colormaps
"""
function setcolormap(cmap)
    GR.setcolormap(cmap)
    COLOR_INDICES[:colormap] = cmap
end

"""
    colormap(T::DataType=UInt32)

Return a vector with the byte-ordered hexadecimal color values of the
current colormap, with integer types defined by `T`.
"""
colormap(t::Type{T}=UInt32) where {T <: Integer} = [t(GR.inqcolor(i)) for i ∈ 1000:1255]

"""
    colormap()

Return a vector with the RGB values of the current colormap.
"""
rgbcolormap() = colormap() .|> switchbytes .|> rgb


"""
    to_rgba(value[, alpha, cmap])

Calculate the hexadecimal color code of a normalized value between 0 and 1
in the current colormap (byte-ordered).

Optionally, the level of the `alpha` channel can be passed as a value
between 0 (transparent) and 1 (opaque), and a custom colormap can be
defined by `cmap` with the corresponding RGB values
(as byte-ordered hexadecimal colors or triplets of normalized float values).
"""
function to_rgba(value, alpha, cmap=colormap()::Vector{<:Integer})
    isnan(value) && return zero(UInt32)
    color = UInt32(cmap[round(Int, value * 255 + 1)])
    return color + round(UInt32, alpha * 255) << 24
end

function to_rgba(value, alpha, cmap::Vector{<:Tuple})
    cmap_int = cmap .|> color .|> switchbytes
    t_rgba(value, alpha, cmap_int)
end


function to_rgba(value)
    isnan(value) && return zero(UInt32)
    colormap()[round(Int, value * 255 + 1)] + 0xff000000
end


# Color schemes

"""
    applycolorscheme(scheme)

Apply the given color scheme, coded as an integer number between 0 and 4.
See [`colorscheme`](@ref) for the values of the color schemes.
"""
function applycolorscheme(scheme)
    # Default to transparent background if no scheme is given
    scheme == 0 && return nothing
    # Replace the default color indices
    for colorind in 1:8
        color = COLORS[colorind, scheme]
        r, g, b = rgb(color)
        # "basic colors"
        GR.setcolorrep(colorind - 1, r, g, b)
        # "distinct colors" (except for the first scheme)
        if scheme ≠ 1
            GR.setcolorrep(DISTINCT_CMAP[colorind], r, g, b)
        end
    end
    # Background RGB values
    r, g, b = rgb(COLORS[1, scheme])
    # Difference between foreground and background
    rdiff, gdiff, bdiff = rgb(COLORS[2, scheme]) .- (r, g, b)
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
"""
function colorscheme(scheme::Int)
    COLOR_INDICES[:scheme] = scheme
    COLOR_INDICES[:background] = (scheme == 0) ? -1 : 0
    return nothing
end

function colorscheme(scheme::AbstractString)
    scheme = replace(scheme, " " => "")
    scheme = lowercase(scheme)
    scheme_dict = Dict("none" => 0, "light" => 1, "dark" => 2,
        "solarizedlight" => 3, "solarizeddark" => 4)
    colorscheme(scheme_dict[scheme])
end
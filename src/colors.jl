const COLORS = hcat(
    [0xffffff, 0x000000, 0x0000ff, 0x00ff00, 0xff0000, 0xffff00, 0x00ffff, 0xff00ff],
    [0x342c28, 0xe0dad7, 0x424ecb, 0x7cc299, 0xfca985, 0xc1b65a, 0x6a9ad0, 0xdb7bc5],
    [0xe3f6fd, 0x837b65, 0x2f32dc, 0x009985, 0xd28b26, 0x98a12a, 0x0089b5, 0x8236d3],
    [0x362b00, 0x969483, 0x2f32dc, 0x009985, 0xd28b26, 0x98a12a, 0x0089b5, 0x8236d3]
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
corresponding to a given hexadecimal color value (byte-ordered).
"""
function rgb(color::Integer)
    r = float( color        & 0xff) / 255.0
    g = float((color >> 8)  & 0xff) / 255.0
    b = float((color >> 16) & 0xff) / 255.0
    return (r, g, b)
end

"""
    rgba(color)

Return the normalized RGBA values (between 0 and 1)
corresponding to a given hexadecimal color value (byte-ordered).
"""
function rgba(color::Integer)
    r, g, b = rgb(color)
    a = float((color >> 24) & 0xff) / 255.0
    return (r, g, b, a)
end

"""
    hexcolor(r, g, b, a=1.0)

Return the hexadecimal integer (byte-ordered)
corresponding to the given RGBA values.

The alpha channel is optional, and defined as 1.0 (opaque) by default.
"""
function hexcolor(r, g, b, a=1.0)
    rint = round(UInt32, r * 255)
    gint = round(UInt32, g * 255)
    bint = round(UInt32, b * 255)
    aint = round(UInt32, a * 255)
    return aint << 24 + bint << 16 + gint << 8 + rint
end

"""
    color(r, g, b)

Return the color index of RGB normalized values between 0 and 1
"""
color(r, g, b) = GR.inqcolorfromrgb(r, g, b)


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

Return a vector with the hexadecimal color values of the current colormap.

By default the vector is
"""
colormap(t::Type{T}=UInt32) where {T <: Integer} = [t(GR.inqcolor(i)) for i ∈ 1000:1255]

"""
    colormap()

Return a vector with the RGB values of the current colormap.
"""
rgbcolormap() = rgb.(colormap())


"""
    to_rgba(value[, alpha, cmap])

Calculate the hexadecimal color code of a normalized value between 0 and 1
in the current colormap.

Optionally, the level of the `alpha` channel can be passed as a value
between 0 (transparent) and 1 (opaque), and a custom colormap can be
defined by `cmap` as a matrix with 256 rows and 3 columns, with the
corresponding RGB values (as `UInt8` or normalized float values).
"""
function to_rgba(value, alpha, cmap=colormap())
    isnan(value) && return zero(UInt32)
    color = cmap[round(Int, value * 255 + 1)]
    return color + round(UInt32, alpha * 255) << 24
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
        rv = r + f*rdiff
        gv = g + f*gdiff
        bv = b + f*bdiff
        GR.inqcolorfromrgb(rv, gv, bv)
        GR.setcolorrep(79 + colorind, rv, gv, bv)
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
    applycolorscheme(scheme) # needed if colors() has to be used
end

function colorscheme(scheme::AbstractString)
    scheme = replace(scheme, " " => "")
    scheme = lowercase(scheme)
    scheme_dict = Dict("none" => 0, "light" => 1, "dark" => 2,
        "solarizedlight" => 3, "solarizeddark" => 4)
    colorscheme(scheme_dict[scheme])
end

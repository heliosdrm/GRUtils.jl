const COLORS = hcat(
    [0xffffff, 0x000000, 0x0000ff, 0x00ff00, 0xff0000, 0xffff00, 0x00ffff, 0xff00ff],
    [0x342c28, 0xe0dad7, 0x424ecb, 0x7cc299, 0xfca985, 0xc1b65a, 0x6a9ad0, 0xdb7bc5],
    [0xe3f6fd, 0x837b65, 0x2f32dc, 0x009985, 0xd28b26, 0x98a12a, 0x0089b5, 0x8236d3],
    [0x362b00, 0x969483, 0x2f32dc, 0x009985, 0xd28b26, 0x98a12a, 0x0089b5, 0x8236d3]
)

const DISTINCT_CMAP = [ 0, 1, 984, 987, 989, 983, 994, 988 ]

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
    setcolormap(cmap)

Set the current colormap to one of the built-in colormaps
"""
setcolormap(cmap) = GR.setcolormap(cmap)

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

"""
    setcolors(scheme)

Set the values of discrete color series to a given scheme.
The argument `scheme` must be an integer number between 0 and 4.
"""
function setcolors(scheme)
    scheme == 0 && (return nothing)
    # Take the column for the given scheme
    # and replace the default color indices
    for colorind in 1:8
        color = COLORS[colorind, scheme]
        # if colorind == 1
        #     background = color
        # end
        r, g, b = rgb(color)
        # replace the indices corresponding to "basic colors"
        GR.setcolorrep(colorind - 1, r, g, b)
        # replace also the ones for "distinct colors" (unless for the first index)
        if scheme ≠ 1
            GR.setcolorrep(DISTINCT_CMAP[colorind], r, g, b)
        end
    end
    # Background RGB values
    r, g, b = rgb(COLORS[1, scheme])
    # Difference between foreground and background
    rdiff, gdiff, bdiff = rgb(COLORS[2, scheme]) .- (r, g, b)
    # replace the 12 "grey" shades
    for colorind in 1:12
        f = (colorind - 1) / 11.0
        GR.setcolorrep(92 - colorind, r + f*rdiff, g + f*gdiff, b + f*bdiff)
    end
    return nothing
end

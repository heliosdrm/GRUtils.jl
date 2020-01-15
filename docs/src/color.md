```@setup colors
using GRUtils, Random
Random.seed!(111)
```
# Color management

GRUtils uses various color sets for different purposes:
color schemes for the general design of the plots, continuous colormaps to represent numeric data in a color scale, and a set of predefined colors with maximum contrast that are used to distinguish different data series in the same plot. Moreover, there is a space available for arbitrary user-defined colors based on RGB codes.

## Color scheme

Color schemes are based on a monochromatic scale between a "foreground" and a "background" color (e.g. black and white), and a set of basic or "accent" colors that approximate the six standard secondary colors: red, green, blue, cyan, yellow and magenta.

By default there are light and dark flavours of both standard and solarized schemes, whose background, foreground and the other basic colors can be seen below.

```@example colors
Figure((600,300)) # hide
geoms = [GRUtils.Geometry(:bar, x=[-2,-1], y=[-2,-1], # hide
    color=GRUtils.switchbytes(UInt32(GRUtils.GR.inqcolor(i)))) # hide
    for i ∈ GRUtils.BASIC_COLORS[3:end]] # hide
axes = GRUtils.Axes(:axes2d, geoms, xlim=(0,1), ylim=(0,1), xticks=(0,0), yticks=(0,0)) # hide
for (s, schemename) in enumerate(("LIGHT", "DARK", "SOLARIZED LIGHT", "SOLARIZED DARK")) # hide
    sp = subplot(2,2,s).attributes[:subplot] # hide
    GRUtils.makeplot!(currentplot(), axes, geoms, subplot=sp, scheme=s) # hide
    legend("red","green","blue","cyan","yellow","magenta", location="center",maxrows=3) # hide
    title("\\n$schemename") # hide
end # hide
gcf() # hide
```

## Colormaps

Colormaps are based on a scale of 256 contiguous colors that can be used to represent numeric ranges. GRUtils uses the "Viridis" colormap by default (see below), with the option of changing to any of the [48 built-in colormaps of GR](https://gr-framework.org/colormaps.html).

```@example colors
Figure((600,200)) # hide
im = ones(25) .* reshape(LinRange(0,1,256), 1, 256) # hide
im = reshape(LinRange(0,1,256), 1, 256) # hide
heatmap(im, colorbar=false, colormap=44, overlay_axes=true) # hide
yticks(0,0) # hide
xticks(25.6,1) # hide
xticklabels(x -> Base.Printf.@sprintf("%0.2f", x/256)) # hide
```

## High-contrast color set

When various geometries of the same kind are included in the same plot (e.g. line plots with multiple data series), they are drawn using the predefined sequence of colors that is shown below -- unless a specific color is explicitly set by the user. That sequence has 20 different colors that approach [Kelly’s list of colors with maximum contrast](http://www.iscc-archive.org/pdf/PC54_1724_001.pdf) (leaving aside white and black), and the order of the first colors is reminiscent of the sequence used by GNU Octave or Matlab.

```@example colors
Figure((600, 150)) # hide
geoms = [GRUtils.Geometry(:bar, x=[-0.5,0.5] .+ i, y=[0,1], # hide
    color=GRUtils.switchbytes( # hide
        UInt32(GRUtils.GR.inqcolor(GRUtils.SERIES_COLORS[i])) # hide
    )) # hide
    for i = 1:20] # hide
axes = GRUtils.Axes(:axes2d, geoms, # hide
    xticks=(1,1), yticks=(0,0), # hide
    xlim=(0.5,20.5) # hide
) # hide
GRUtils.makeplot!(currentplot(), axes, geoms) # hide
gcf() # hide
```

## User-defined colors

Custom colors can be defined as hexadecimal codes joining the values of 8-bit RGB channels. E.g. the number \#FF6600 defines a bright orange color (R = \#FF, G = \#66, B = \#00). Those codes can be defined directly as integer numbers, or from the RGB values normalized between 0 and 1, with the function `color` (unexported). For instance, the code \#FF6600 can be defined in any of the following ways:

```julia
0xff6600                   # UInt32 number, equivalent to 16_737_792
GRUtils.color(1, 0.4, 0)   # R = 1, G = 0.4, B= 0
```

!!! warning

    The RGB channels in those hexadecimal color codes are assumed to be "word-ordered" in a little-endian system, i.e. the red-green-blue bytes are ordered from the most to the least significant. Take care of the byte order if you use integer color codes calculated from other sources.



The color system of GR, used by GRUtils, has room for nearly 1,000 colors defined ad hoc by the user in each session -- let aside the color sets that have already been commented. There are more than 16 million of possible RGB combinations, although in practice you will never need more than a small fraction of the space for user-defined colors.

## Using colors with GRUtils

The general color scheme and the colormap are set globally, but they can be changed at any time during the session with the functions [`colorscheme`](@ref) and [`colormap`](@ref), or chosen specifically for particular plots with [`colorscheme!`](@ref) and [`colormap!`](@ref).

The high-contrast color set is managed automatically during the creation of plots, if no other colors are selected by the user. There are two ways to specify particular colors, depending on the kind of geometry:

* Geometries based on lines and markers (e.g. in 2D or 3D line plots, among others), can receive a format string, as in [matplotlib](https://matplotlib.org/3.1.1/api/_as_gen/matplotlib.pyplot.plot.html). Such strings may contain characters that correspond to the basic colors of the scheme:

    * `'r'` for **r**ed,
    * `'g'` for **g**reen,
    * `'b'` for **b**lue,
    * `'c'` for **c**yan,
    * `'y'` for **y**ellow,
    * `'m'` for **m**agenta,
    * `'k'` for the foreground color (blac**k** in the default scheme),
    * `'w'` for the background color (**w**hite in the default scheme).
* Moreover, user-defined colors can be specified for the following attributes of some plot elements:
    * `backgroundcolor` for the background,
    * `linecolor` for lines,
    * `markercolor` for markers,
    * `color` for filled areas in bars, isosurfaces, etc.

This can be done during the creation of the plots, as in the following examples:

```@example colors
Figure() # hide
# Format string for a red line (straight)
plot(LinRange(0, 1, 10), "-r")
hold(true)
# Add a purple line (curved)
plot(exp.(LinRange(-1, 0, 10)),
    linecolor=GRUtils.color(0.5, 0, 0.75))
```

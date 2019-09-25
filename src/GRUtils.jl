module GRUtils

import GR

export Figure, gcf, subplot, currentplot, draw,
    plot, plot3, polar, scatter, scatter3, stair, stem, oplot,
    barplot, histogram, polarhistogram,
    contour, contourf, tricont, trisurf, surface, wireframe,
    heatmap, polarheatmap, hexbin, imshow, isosurface, shade,
    aspectratio, colorbar, grid, hold, legend, title,
    xflip, xlabel, xlim, xlog, xticks, xticklabels,
    yflip, ylabel, ylim, ylog, yticks, xticklabels,
    zflip, zlabel, zlim, zlog, zticks,

    subplot!, plot!, plot3!, polar!, scatter!, scatter3!, stair!, stem!, oplot!,
    barplot!, histogram!, polarhistogram!,
    contour!, contourf!, tricont!, trisurf!, surface!, wireframe!,
    heatmap!, polarheatmap!, hexbin!, imshow!, isosurface!, shade!,
    aspectratio!, colorbar!, grid!, hold!, legend!, title!,
    xflip!, xlabel!, xlim!, xlog!, xticks!, xticklabels!,
    yflip!, ylabel!, ylim!, ylog!, yticks!, xticklabels!,
    zflip!, zlabel!, zlim!, zlog!, zticks!


function search(s::AbstractString, c::Char)
    result = findfirst(isequal(c), s)
    result != nothing ? result : 0
end

const COLORS = [
    [0xffffff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0x00ffff, 0xffff00, 0xff00ff] [0x282c34, 0xd7dae0, 0xcb4e42, 0x99c27c, 0x85a9fc, 0x5ab6c1, 0xd09a6a, 0xc57bdb] [0xfdf6e3, 0x657b83, 0xdc322f, 0x859900, 0x268bd2, 0x2aa198, 0xb58900, 0xd33682] [0x002b36, 0x839496, 0xdc322f, 0x859900, 0x268bd2, 0x2aa198, 0xb58900, 0xd33682]
    ]

const DISTINCT_CMAP = [ 0, 1, 984, 987, 989, 983, 994, 988 ]

const UNITSQUARE = [0.0, 1.0, 0.0, 1.0]
const NULLPAIR = (0.0, 0.0)

function _min(a)
  minimum(filter(!isnan, a))
end

function _max(a)
  maximum(filter(!isnan, a))
end

include("geometries.jl")
include("axes.jl")
include("legends.jl")
include("colorbars.jl")
include("plotobjects.jl")
include("text.jl")
include("figures.jl")
include("frontend.jl")
include("attributes.jl")

const EMPTYFIGURE = Figure((0.0, 0.0), [PlotObject()])
const CURRENTFIGURE = Ref(EMPTYFIGURE)

"""
  gcf()

Get the global current figure.
"""
gcf() = (CURRENTFIGURE[] == EMPTYFIGURE) ? Figure() : CURRENTFIGURE[]

end # module

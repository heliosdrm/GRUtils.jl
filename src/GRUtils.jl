module GRUtils

import GR

export Figure, gcf, subplot, currentplot, draw, savefig,
    plot, plot3, polar, scatter, scatter3, stair, stem, oplot,
    errorbar, barplot, histogram, polarhistogram,
    contour, contourf, shade, surface, tricont, trisurf, volume, wireframe,
    heatmap, polarheatmap, hexbin, imshow, isosurface,
    aspectratio, colorbar, grid, hold, legend, radians,
    title, panzoom, zoom,
    xflip, xlabel, xlim, xlog, xticks, xticklabels,
    yflip, ylabel, ylim, ylog, yticks, xticklabels,
    zflip, zlabel, zlim, zlog, zticks,

    subplot!, plot!, plot3!, polar!, scatter!, scatter3!, stair!, stem!, oplot!,
    errorbar!, barplot!, histogram!, polarhistogram!,
    contour!, contourf!, shade!, surface!, tricont!, trisurf!, volume!, wireframe!,
    heatmap!, polarheatmap!, hexbin!, imshow!, isosurface!,
    aspectratio!, colorbar!, grid!, hold!, legend!, title!,
    radians!, panzoom!, zoom!,
    xflip!, xlabel!, xlim!, xlog!, xticks!, xticklabels!,
    yflip!, ylabel!, ylim!, ylog!, yticks!, xticklabels!,
    zflip!, zlabel!, zlim!, zlog!, zticks!

include("general.jl")
include("colors.jl")
include("geometries.jl")
include("axes.jl")
include("legends.jl")
include("colorbars.jl")
include("plotobjects.jl")
include("text.jl")
include("figures.jl")
include("frontend.jl")
include("attributes.jl")

end # module

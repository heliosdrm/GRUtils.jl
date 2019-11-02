module GRUtils

import GR
using LinearAlgebra

export Figure, gcf, subplot, currentplot, draw, savefig, video, videofile,
    plot, plot3, polar, quiver, quiver3, scatter, scatter3, stair, stem, oplot,
    errorbar, barplot, histogram, polarhistogram,
    contour, contourf, shade, surface, tricont, trisurf, volume, wireframe,
    heatmap, polarheatmap, hexbin, imshow, isosurface, annotations,
    aspectratio, colorbar, grid, hold, legend, radians,
    title, panzoom, zoom, perspective, rotate, tilt, turncamera,
    xflip, xlabel, xlim, xlog, xticks, xticklabels,
    yflip, ylabel, ylim, ylog, yticks, yticklabels,
    zflip, zlabel, zlim, zlog, zticks,
    colormap, colorscheme,

    subplot!, plot!, plot3!, polar!, quiver!, quiver3!, scatter!, scatter3!, stair!, stem!, oplot!,
    errorbar!, barplot!, histogram!, polarhistogram!,
    contour!, contourf!, shade!, surface!, tricont!, trisurf!, volume!, wireframe!,
    heatmap!, polarheatmap!, hexbin!, imshow!, isosurface!, annotations!,
    aspectratio!, colorbar!, grid!, hold!, legend!, title!,
    radians!, panzoom!, zoom!, perspective!, rotate!, tilt!, turncamera!,
    xflip!, xlabel!, xlim!, xlog!, xticks!, xticklabels!,
    yflip!, ylabel!, ylim!, ylog!, yticks!, yticklabels!,
    zflip!, zlabel!, zlim!, zlog!, zticks!,
    colormap!, colorscheme!

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
include("animations.jl")

end # module

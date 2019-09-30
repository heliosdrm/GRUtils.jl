flist = (
    ("Line plots", ("plot", "oplot", "stair", "plot3", "polar")),
    ("Scatter plots", ("scatter", "scatter3")),
    ("Stem plots", ("stem",)),
    ("Bar plots", ("barplot",)),
    ("Histograms", ("histogram", "polarhistogram", "hexbin")),
    ("Contour plots", ("contour", "contourf", "tricont")),
    ("Surface plots", ("surface", "trisurf", "wireframe")),
    ("Volume rendering", ("volume",)),
    ("Heatmaps", ("heatmap", "shade")),
    ("Images", ("imshow",)),
    ("Isosurfaces", ("isosurface",))
)

open("./src/api.md", "w") do file begin
        write(file, "# API reference\n\n")
        write(file, "## Plotting functions\n\n")
        write(file, """
        ```@setup plot
        using GRUtils, Random
        Random.seed!(111)
        ```
        """)
        for data in flist
            section = data[1]
            write(file, "### $section\n")
            for fun in data[2]
                write(file, """
                ```@docs
                $fun
                ```
                ```@example plot
                GRUtils.Figure(); # hide
                Base.include(GRUtils, "../examples/docstrings/$fun.jl") # hide
                ```
                """)
            end
        end
    end
end

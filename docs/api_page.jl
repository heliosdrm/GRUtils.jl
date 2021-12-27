open("./src/api/plotting.md", "w") do file begin
        write(file, """
        ```@setup plot
        using GRUtils, Random
        Random.seed!(111)
        ```
        """)
        write(file, "# Plotting functions\n\n")
        for data in (
            ("Line plots", ("plot", "oplot", "stairs", "plot3", "polar")),
            ("Scatter plots", ("scatter", "scatter3")),
            ("Stem plots", ("stem", "errorbar")),
            ("Bar plots", ("barplot",)),
            ("Vector fields", ("quiver", "quiver3")),
            ("Histograms", ("histogram", "polarhistogram", "hexbin")),
            ("Contour plots", ("contour", "contourf", "tricont")),
            ("Surface plots", ("surface", "trisurf", "wireframe")),
            ("Volume rendering", ("volume",)),
            ("Heatmaps", ("heatmap", "polarheatmap", "shade")),
            ("Images", ("imshow",)),
            ("Isosurfaces", ("isosurface",)),
            ("Text", ("annotations",))
        )
            section = data[1]
            write(file, "## $section\n")
            for fun in data[2]
                write(file, """
                ```@docs
                $fun
                ```
                ```@example plot
                Figure(); # hide
                Base.include(GRUtils, "../examples/docstrings/$fun.jl") # hide
                ```
                """)
            end
        end
    end
end

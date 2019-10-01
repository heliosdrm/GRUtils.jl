open("./src/api.md", "w") do file begin
        write(file, """
        ```@setup plot
        using GRUtils, Random
        Random.seed!(111)
        ```
        """)
        write(file, "# API reference\n\n")
        # Plotting functions
        write(file, "## Plotting functions\n\n")
        for data in (
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
        # Attributes
        write(file, "## Plot attributes\n\n")
        for data in (
            ("Title", ("title",)),
            ("Axis guides", ("xlabel", "xticks", "xticklabels", "grid")),
            ("Axis size", ("xlim", "aspectratio", "zoom", "panzoom")),
            ("Axis scales", ("xlog", "xflip")),
            ("Geometry guides", ("legend", "colorbar"))
        )
            section = data[1]
            write(file, "### $section\n```@docs\n")
            for fun in data[2]
                write(file, "$fun\n")
            end
            write(file, "```\n")
        end
        # Control operations
        write(file, """
        ## Control operations
        ```@docs
        """)
        for fun in ("Figure", "gcf", "currentplot", "subplot", "hold", "savefig")
            example_file = "../examples/docstrings/$fun.jl"
            write(file, "$fun\n")
            if isfile(example_file)
                write(file, """
                ```
                ```@example plot
                GRUtils.Figure(); # hide
                Base.include(GRUtils, "$example_file") # hide
                ```
                ```@docs
                """)
            end
        end
        write(file, "```\n")
    end
end

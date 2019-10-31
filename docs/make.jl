using Documenter, GRUtils

include("api_page.jl")

makedocs(sitename="GRUtils.jl",
    pages = [
        "Introduction" => "index.md",
        "Multiple plots" => "multiple.md",
        "Animations" => "animations.md",
        "Color management" => "color.md",
        "API reference" => [
            "api/plotting.md",
            "api/attributes.md",
            "api/control.md"
        ],
        "Internals" => [
            "internals/structure.md",
            "internals/drawing.md",
            "internals/createplots.md",
            "internals/extending.md"
        ]
    ],
    expandfirst = ["index.md"]
)

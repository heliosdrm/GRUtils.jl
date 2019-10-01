using Documenter, GRUtils

include("api_page.jl")

makedocs(sitename="GRUtils.jl",
    pages = [
        "Introduction" => "index.md",
        "Multiple plots" => "multiple.md"
        "api.md"
    ],
    format = Documenter.HTML(prettyurls = false)
)

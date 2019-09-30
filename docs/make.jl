using Documenter, GRUtils

include("api_page.jl")

makedocs(sitename="GRUtils.jl",
    pages = [
        "Introduction" => "index.md",
        "api.md"
    ],
    format = Documenter.HTML(prettyurls = false)
)

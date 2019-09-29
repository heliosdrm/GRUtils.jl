using Documenter, GRUtils

makedocs(sitename="GRUtils",
    pages = [
        "index.md",
        "Basics" => "basics.md"
    ],
    format = Documenter.HTML(prettyurls = false)
)

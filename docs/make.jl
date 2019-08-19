using Documenter, JPEGs

makedocs(
    modules = [JPEGs],
    format = :html,
    checkdocs = :exports,
    sitename = "JPEGs.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/maccam912/JPEGs.jl.git",
)

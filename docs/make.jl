using Documenter, Biosecurity

makedocs(
    modules = [Biosecurity],
    sitename = "Biosecurity.jl"
)

deploydocs(
    repo = "github.com/cesaraustralia/Biosecurity.jl.git",
)

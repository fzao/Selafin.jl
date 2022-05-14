using Documenter
using Selafin

makedocs(
    sitename = "Selafin",
    format = Documenter.HTML(),
    modules = [Selafin]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#

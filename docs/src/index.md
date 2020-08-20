```@meta
CurrentModule = GRUtils
```
# Introduction to GRUtils

[GRUtils](https://github.com/heliosdrm/GRUtils.jl) is a refactoring of the module `jlgr` from [GR](https://github.com/jheinen/GR.jl), a graphics package for Julia. The purpose of GRUtils is to provide the main utilities of `jlgr` in a more "Julian" and modular style, easier to read, and facilitate code contributions by others.

GRUtils is being maintained in a package apart from GR, in order to make its development faster, assuming a temporary duplication of development efforts. Hopefully in a near future it will be clearer if the interface to GR provided in GRUtils deserves maintenance in such an independent "plug-in", or if its code should be integrated in GR itself.

## Installation

Add GRUtils to your library of Julia packages, typing `]` to enter in the "package management mode" and then typing:

```julia-repl
add GRUtils
```

Or if you feel like looking into GRUtils' code and maybe trying your own fixes and improvements, you can clone it for development (also in the package management mode):

```julia-repl
dev GRUtils
```

This package depends on [GR](https://github.com/jheinen/GR.jl). If you don't have it installed before, GRUtils will install GR and its dependencies. Building GR ocassionally fails; so to ensure that everything will work, check the messages printed after the installation, and if there is some error related to "Building GR", retry:

```julia-repl
julia> ENV["GRDIR"] = ""
pkg> build GR
```

(The `julia>` and `pkg>` tags do not have to be typed; they are there only to mark that the first instruction is in the normal REPL mode, and the second one in package management mode.)

## A basic example

Let's see an example of a plot to start with:

```@example plot
# Of course first you have to load the package
using GRUtils
Figure(); # hide
# Example data
x = LinRange(0, 10, 500)
y = sin.(x.^2) .* exp.(-x)
# Making a line plot is as simple as this:
plot(x, y)
# Then hold the plot to add the envelope...
hold(true)
# The envelope is given in two columns,
# plotted as dashed lines ("--") in black color ("k")
plot(exp.(0:10).^-1 .* [1 -1], "--k")
# Now set the Y-axis limits, and annotate the plot
ylim(-0.5, 0.5)
legend("signal", "envelope")
xlabel("X")
ylabel("Y")
title("Example plot")
```

Depending on what environment you use (e.g. the Julia REPL, a Jupyter notebook, Atom or another IDE), this plot will be displayed in a different device (a plotting window, panel, a cell of the notebook...). If you want to keep it as an image file, use the function [`savefig`](@ref), like this:

```julia
savefig("example.svg")
```

The type of the file will be determined by the extension of the file. The list of available file types depends on the installed workstation, but common types (SVG, PNG, JGP, GIF, PS, PDF...) are usually supported.

## Relationship with GR's API

Many more functions to make and manipulate plots are also available in GRUtils. Those functions have been designed to mimic the [API of GR for Julia](https://gr-framework.org/julia-jlgr.html), so if you have been using GR before, you may use them mostly in the same way. These are the most remarkable differences:

* The radius of [`polar`](@ref) plots always has its centre at zero, instead of the minimum value of the represented data.
* The angle labels in [`polar`](@ref) and [`polarhistogram`](@ref) are by default in radians; and the bins of `polarhistogram` are by default positioned according to the values of the input.
* Matrices passed to [`imshow`](@ref) must contain numbers in the range [0, 1].
* The function [`isosurface`](@ref) does not assume a default "isovalue", which has to be entered explicitly as second positional argument.
* Staircase plots (not present in GR's documentation) are made with the function [`stair`](@ref) instead of `step`, in order to avoid name conflicts with [Base.step](https://docs.julialang.org/en/latest/base/collections/#Base.step).

Some plots in GRUtils also allow extra features. Check the list of [Plotting functions](@ref) for more details.

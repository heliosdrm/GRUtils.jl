---
layout: default
title: Basic instructions
---
# Basic instructions

## Installation

Add GRUtils to your library of Julia packages, hitting `]` to enter in the "package management mode" and then typing:

```julia-repl
add GRUtils
```

Or if you feel like looking into GRUtil's code and maybe trying your own fixes and improvements, you can clone it for development (also in the package management mode):

```julia
dev GRUtils
```

This package depends on [GR](https://github.com/jheinen/GR.jl). If you don't have it installed before, GRUtils will install GR and its dependencies. Building GR ocassionally fails; so to ensure that everything will work, check the messages printed after the installation, and if there is some error related to "Building GR", retry:

```julia-console
# In "normal" REPL
julia> ENV["GRDIR"] = ""
# And in "pkg mode" (after `]`)
pkg> build GR
```

(The `julia>` and `pkg>` tags do not have to be typed; they are there only to mark that the first instruction is in the normal REPL mode, and the second one in package management mode.)

## Basic usage

The documentation of [GR's API for Julia](https://gr-framework.org/julia-jlgr.html) is in its majority valid for the usage of GRUtils too. These are the most remarkable differences:

* All the plotting functions that can take matrices as bi-dimensional inputs ([`contour`](https://gr-framework.org/julia-jlgr.html#contour-0315ff05d8f2652c7841da75a23d12e6), [`contourf`](https://gr-framework.org/julia-jlgr.html#contourf-0315ff05d8f2652c7841da75a23d12e6), [`surface`](https://gr-framework.org/julia-jlgr.html#surface-0315ff05d8f2652c7841da75a23d12e6), [`wireframe`](https://gr-framework.org/julia-jlgr.html#wireframe-0315ff05d8f2652c7841da75a23d12e6), [`heatmap`](https://gr-framework.org/julia-jlgr.html#heatmap-849ebfcad83c4c0251a8873748f01036)) consider that X coordinates are mapped to columns and Y to rows of the input matrix.
* Matrices passed to [`imshow`](https://gr-framework.org/julia-jlgr.html#imshow-404f4e72a2ec356c3761e3179229e416) must contain numbers in the range [0, 1].
* Staircase plots (not present in the documentation) are made with the function `stair` instead of `step`, in order to avoid name conflicts with [Base.step](https://docs.julialang.org/en/latest/base/collections/#Base.step).
* The [functions that modify plot attributes](https://gr-framework.org/julia-jlgr.html#attribute-functions) update the visualization of the plot automatically.

Continue in the next section to read about how to [work with multiple plots](./multipleplots.md).

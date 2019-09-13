---
layout: default
title: Introduction to GRUtils
---
# Introduction to GRUtils

This package is a refactoring of the module `jlgr` from [GR](https://github.com/jheinen/GR.jl). The purpose of GRUtils is to provide the main utilities of `jlgr` in a more "Julian" and modular style, easier to read, and facilitate code contributions by others.

GRUtils is being maintained in a package apart from GR, in order to make its development faster. However it is not yet registered, so to install and test it you will need to do:

```julia
Pkg.clone("https://github.com/heliosdrm/GRUtils.jl")
```

The reason for GRUtils not being registered is that its author does not feel totally right duplicating code. Hopefully in a near future it will be clearer if the interface to GR provided in GRUtils deserves maintenance in such an independent "plug-in", or integrated in GR itself, or if it just becomes a failed experiment.

Read more to learn about:

* [Structure of plots in GRUtils](./structure.md)
* [Creating plots](./createplots.md)
* [Drawing plots](./drawplots.md)
* [Extending GRUtils](./extending.md)

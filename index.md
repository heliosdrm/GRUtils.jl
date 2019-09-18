---
layout: default
title: Introduction to GRUtils
---
# Introduction to GRUtils

This package is a refactoring of the module `jlgr` from [GR](https://github.com/jheinen/GR.jl), a graphics package for Julia. The purpose of GRUtils is to provide the main utilities of `jlgr` in a more "Julian" and modular style, easier to read, and facilitate code contributions by others.

GRUtils is being maintained in a package apart from GR, in order to make its development faster, assuming a temporary duplication of development efforts. Hopefully in a near future it will be clearer if the interface to GR provided in GRUtils deserves maintenance in such an independent "plug-in", or if its code should be integrated in GR itself.

Read more to learn:

* How to use GRUtils:
  - [Installation and basic usage](./usage/basics.md)
  - [Working with multiple plots](./usage/multipleplots.md)
* The internals of GRUtils, and how to contribute to its development:
  - [Structure of plots in GRUtils](./internals/structure.md)
  - [Drawing plots](./internals/drawplots.md)
  - [Creating plots](./internals/createplots.md)
  - [Extending GRUtils](./internals/extending.md)

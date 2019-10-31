```@setup plot
using GRUtils
```
# Control operations
```@docs
Figure(::Any, ::String)
gcf
currentplot
subplot
```
```@example plot
Figure(); # hide
Base.include(GRUtils, "../examples/docstrings/subplot.jl") # hide
```
```@docs
hold
savefig
```
# Animations
```@docs
movie
```
```@example plot
Figure(); # hide
Base.include(GRUtils, "../examples/docstrings/movie.jl") # hide
```
```@docs
savemovie
```

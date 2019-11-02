```@setup plot
using GRUtils
```
# Control operations

## Figures and plots initialization/referencing
```@docs
Figure(::Any, ::String)
gcf
currentplot
```
## Multiple plots
```@docs
hold
subplot
```
```@example plot
Figure(); # hide
Base.include(GRUtils, "../examples/docstrings/subplot.jl") # hide
```
## Animations
```@docs
video
```
## Save to files
```@docs
savefig
videofile
```

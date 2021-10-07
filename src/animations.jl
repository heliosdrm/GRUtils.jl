function resetmime(mime)
    GR.reset()
    if !isempty(mime)
        GR.inline(mime)
    end
end

"""
    videofile(fun::Function, target, overwrite=false)
    videofile(figs::AbstractArray{<:Fig}, target, overwrite=false)

Make a video from a function or an array of figures and save it into a file.

The first argument can be an array of `Figures` that will be displayed
as a sequence of frames in the video, or a function without arguments that draws
the figures (normally a loop where the figures are created and drawn one after another).
That function can be defined anonymously in the call to `videofile` with
the `do` syntax (see the example).

The secondargument `target` must be a string with the name of
the video file, whose format is determined by the extension of the file.
The supported extensions are `"webm"`, `"mp4"` or `"mov"`.

Use `overwrite=true` to force the creation of `target` if the file already exists
(otherwise an error will be thrown in such cases).

# Examples

```julia
# Make a plot with example data
x = LinRange(0, 800, 100)
y = sind.(x)
plot(x,y)
# Make a video sliding over the X axis
videofile("sin.mp4") do
  for d = 0:10:440
    xlim(d, d+360)
    draw(gcf())
  end
end
```
"""
function videofile(fun::Function, target, overwrite=false)
    name, ext = splitext(target)
    if length(ext) < 2
        ext = ".webm"
    end
    mime = GR.isinline() ? string(GR.mime_type[]) : ""
    GR.inline(ext[2:end])
    try
        fun()
        tmpfile = ENV["GKS_FILEPATH"]
        resetmime(mime)
        return mv(tmpfile, target; force=overwrite)
    catch err
        resetmime(mime)
        throw(err)
    end
end

"""
    video(fun::Function, target="webm")
    video(figs::AbstractArray{<:Fig}, target="webm")

Make a video from a function or an array of figures.

The first argument can be an array of `Figures` that will be displayed
as a sequence of frames in the video, or a function without arguments that draws
the figures (normally a loop where the figures are created and drawn one after another).
That function can be defined anonymously in the call to `video` with
the `do` syntax (see the example).

The second (optional) argument `target` must be a string with
one of the formats `"webm"` (default), `"mp4"` or `"mov"`.

The output is an object that may be displayed as a video of the given format
(depending on the supported MIME outputs of the environment).
Use [`videofile`](@ref) to save such a video in a file.

# Examples

```julia
# Make a plot with example data
x = LinRange(0, 800, 100)
y = sind.(x)
plot(x,y)
# Make a video sliding over the X axis
video("webm") do
  for d = 0:10:440
    xlim(d, d+360)
    draw(gcf())
  end
end
```
"""
function video(fun::Function, target="webm")
    mime = GR.isinline() ? string(GR.mime_type[]) : ""
    GR.inline(target)
    try
        fun()
        output = GR.show()
        resetmime(mime)
        return output
    catch err
        resetmime(mime)
        throw(err)
    end
end

for fun in (:video, :videofile)
    @eval function $fun(figs::AbstractArray{<:Figure}, args...)
        f = () -> for fg in figs draw(fg) end
        $fun(f, args...)
    end
end

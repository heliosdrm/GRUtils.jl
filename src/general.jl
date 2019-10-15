const UNITSQUARE = [0.0, 1.0, 0.0, 1.0]
const NULLPAIR = (0.0, 0.0)

_min(a) = minimum(filter(!isnan, a))
_max(a) = maximum(filter(!isnan, a))

function hasnan(a)
    for el ∈ a
        (el === NaN || el === missing) && return true
    end
    return false
end

_index(item::Real, args...) = Int(item)

function _index(item, collection, base=1, default=nothing)::Union{Int, Nothing}
    ix = indexin([item], collection)[1]
    ix isa Nothing && return default
    return ix - 1 + base
end

# Fetch example from filename and return it as String
_example(name) = read(joinpath(dirname(@__FILE__), "../examples/docstrings", "$name.jl"), String)

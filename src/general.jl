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

lookup(item::Real, dict) = Int(item)
lookup(item::T, dict::Dict{T,V}) where {T} where V = dict[item]

# Fetch example from filename and return it as String
_example(name) = read(joinpath(dirname(@__FILE__), "../examples/docstrings", "$name.jl"), String)

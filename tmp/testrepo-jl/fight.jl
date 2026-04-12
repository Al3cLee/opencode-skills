function fight(a::AbstractAnimal, b::AbstractAnimal)
    return "draw"
end

fight(a::Dog, b::Cat) = "win"

fight(a::Cat, b::Dog) = "loss"

fight(a::Human{<:Real}, b::AbstractAnimal) = "win"

fight(a::AbstractAnimal, b::Human{<:Real}) = "loss"

fight(hum1::Human{T}, hum2::Human{T}) where {T <: Real} = hum1.height > hum2.height ? "win" : "loss"

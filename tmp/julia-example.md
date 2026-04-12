

# Define an abstract type for animals

```julia
abstract type AbstractAnimal end
```

Now, let’s define some concrete animal types:
# Define concrete types for different animals

```julia
struct Dog <: AbstractAnimal
    color::String
end

struct Cat <: AbstractAnimal
    color::String
end

struct Cock <: AbstractAnimal
    gender::Bool
end

struct Human{FT <: Real} <: AbstractAnimal
    height::FT
    function Human(height::T) where T <: Real
        if height <= 0 || height > 300
            error("Human height must be between 0 and 300 cm")
        end
        return new{T}(height)
    end
end
```

Now we fix the error where humans cannot fight each other.

```bash
julia> fight(hum1::Human{T}, hum2::Human{T}) where T<:Real =
    hum1.height > hum2.height ? "win" : "loss"

julia> fight(Cock(true), Cat("red"))
"draw"

julia> fight(Dog("blue"), Cat("white"))
"win"

julia> fight(Human(180), Cat("white"))
"win"

julia> fight(Human(170), Human(180))
"loss"
```

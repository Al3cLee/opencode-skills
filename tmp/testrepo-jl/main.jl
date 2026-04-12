abstract type AbstractAnimal end

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
    function Human(height::T) where {T <: Real}
        if height <= 0 || height > 300
            error("Human height must be between 0 and 300 cm")
        end
        return new{T}(height)
    end
end

include("fight.jl")

println("fight(Cock(true), Cat(\"red\")) = ", fight(Cock(true), Cat("red")))
println("fight(Dog(\"blue\"), Cat(\"white\")) = ", fight(Dog("blue"), Cat("white")))
println("fight(Human(180), Cat(\"white\")) = ", fight(Human(180), Cat("white")))
println("fight(Human(170), Human(180)) = ", fight(Human(170), Human(180)))

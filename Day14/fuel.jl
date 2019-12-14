using DataStructures

struct Ingredient
    name::Symbol
    quantity::Int
end

struct Recipe
    input::Vector{Ingredient}
    output::Ingredient
end

function Ingredient(s::AbstractString)
    quantity, name = strip.(split(s, ' '))
    name = Symbol(name)
    quantity = parse(Int, quantity)
    Ingredient(name, quantity)
end

function Recipe(s::AbstractString)
    input, output = strip.(split(s, "=>"))
    input = Ingredient.(strip.(split(input, ',')))
    output = Ingredient(output)
    Recipe(input, output)
end


function cost(ingredient::Ingredient, recipes::Dict{Symbol,Recipe})
    requirements = DefaultDict{Symbol,Int}(0)
    requirements[ingredient.name] = ingredient.quantity
    while true
        remaining = filter(p -> p.first != :ORE && p.second > 0, requirements)
        isempty(remaining) && break
        name, quantity = rand(remaining)
        recipe = recipes[name]
        factor = max(1, quantity ÷ recipe.output.quantity)
        for ingredient in recipe.input
            requirements[ingredient.name] += ingredient.quantity * factor
        end
        requirements[recipe.output.name] -= factor * recipe.output.quantity
    end
    requirements[:ORE]
end

function maxfuel(total_ore::Int, threshold::Int, recipes::Dict{Symbol,Recipe})
    low = 1
    mid = total_ore ÷ 2 + 1
    high = total_ore
    while true
        spent_ore = cost(Ingredient(:FUEL, mid), recipes)
        if high - low == 1
            return mid
        elseif spent_ore > total_ore
            high = mid
        elseif spent_ore < total_ore
            low = mid
        end
        mid = (high - low) ÷ 2 + low
    end
end

const INPUTFILE = joinpath(@__DIR__, "input.txt")
const recipes = Dict{Symbol,Recipe}((r.output.name, r) for r in Recipe.(readlines(INPUTFILE)))

let goal = Ingredient(:FUEL, 1)
    costperfuel = cost(goal, recipes)
    println("First half: $(costperfuel)")
    println("Second half: $(maxfuel(1000000000000, costperfuel, recipes))")
end

const INPUTFILE = joinpath(@__DIR__, "input.txt")
input = parse.(Int, readlines(INPUTFILE))

fuel(mass)::Int = round(mass / 3, RoundDown) - 2

println("First half: $(sum(fuel.(input)))")

function totalfuel(mass, acc=0)::Int
    if mass < 0 || fuel(mass) < 0
        acc
    else
        totalfuel(fuel(mass), acc + fuel(mass))
    end
end

println("Second half: $(sum(totalfuel.(input)))")

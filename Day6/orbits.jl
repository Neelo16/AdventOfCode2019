using DataStructures

const INPUTFILE = joinpath(@__DIR__, "input.txt")

mutable struct Planet
    name
    orbitedby::Set{Planet}
    orbits::Set{Planet}
    pred::Union{Nothing,Planet}
    visited::Bool
end
Planet(name) = Planet(name, Set(), Set(), nothing, false)

const universe = DefaultDict{String,Planet}(passkey=true) do key
        Planet(key)
end

function readplanets(s::String)
    source, orbit = split(s, ")")
    push!(universe[source].orbitedby, universe[orbit])
    push!(universe[orbit].orbits, universe[source])
end

countorbits(planet::Planet) = length(planet.orbitedby) + countorbits(planet.orbitedby)

countorbits(planets::Union{AbstractSet{Planet},AbstractArray{Planet}}) = sum([0, countorbits.(planets)...])

foreach(readplanets, readlines(INPUTFILE))
println("First half: $(countorbits(collect(values(universe))))")

adjacentplanets(planet::Planet) = Iterators.flatten([planet.orbitedby, planet.orbits])
function shortestpath(start::Planet, dest::Planet)
    queue = Queue{Planet}()
    enqueue!(queue, start)
    for planet in values(universe)
        planet.visited = false
        planet.pred = nothing
    end
    while !isempty(queue)
        next = dequeue!(queue)
        next == dest && break
        for planet in adjacentplanets(next)
            planet.visited && continue
            enqueue!(queue, planet)
            planet.pred = next
            planet.visited = true
        end
    end
    counter = 0
    while dest != start
        dest = dest.pred
        counter += 1
    end
    counter
end

println("Second half: $(shortestpath(universe["YOU"], universe["SAN"]) - 2)")

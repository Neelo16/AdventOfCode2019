const INPUTFILE = joinpath(@__DIR__, "input.txt")

readasteroids(path::AbstractString) = [(x-1, y-1)
    for (y, line) in enumerate(readlines(path))
        for (x, c) in enumerate(line)
            if c == '#'
    ]

function visible(src, points)
    visiblepoints = Set()
    for point in filter(p -> p != src, points)
        v = point .- src
        angle = atan(v...)
        push!(visiblepoints, angle)
    end
    length(visiblepoints)
end

function getstation(points)
    maxtargets = typemin(Int)
    station = nothing
    for point in points
        targets = visible(point, points)
        if targets > maxtargets
            maxtargets = targets
            station = point
        end
    end
    station, maxtargets
end

function laser(src, points)
    targets = Dict()
    for point in filter(p -> p != src, points)
        v = point .- src
        angle = π/2 - atan(v...)
        dist = hypot(v...)
        if angle ∈ keys(targets)
            push!(targets[angle], (dist, point))
        else
            targets[angle] = [(dist, point)]
        end
    end
    for k in keys(targets)
        sort!(targets[k], rev=true)
    end
    orderedtargets = []
    while !isempty(keys(targets))
        for k in sort(collect(keys(targets)))
            push!(orderedtargets, pop!(targets[k])[2])
            isempty(targets[k]) && delete!(targets, k)
        end
    end
    orderedtargets
end

let asteroids = readasteroids(INPUTFILE)
    station, targets = getstation(asteroids)
    println("First half: $(targets)")
    x, y = laser(station, asteroids)[200]
    println("Second half: $(x * 100 + y)")
end

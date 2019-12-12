const INPUTFILE = joinpath(@__DIR__, "input.txt")

const Point = Vector{Int}

struct Moon
    position::Point
    velocity::Point
end
Moon(s::AbstractString) = Moon(parse.(Int, match(r"<x=(-?\d+), y=(-?\d+), z=(-?\d+)>", s).captures), zeros(Int, 3))
Base.copy(m::Moon) = Moon(map(Base.copy, (m.position, m.velocity))...)

gravity(m::Moon, m2::Moon) = sign.(m2.position .- m.position)

function motion!(moons::Vector{Moon})
    for (m1, m2) in Iterators.product(moons, moons)
        m1 === m2 && continue
        m1.velocity .+= gravity(m1, m2)
    end
    for moon in moons
        moon.position .+= moon.velocity
    end
    moons
end

energy(m::Moon) = sum(abs.(m.position)) * sum(abs.(m.velocity))

let moons = Moon.(readlines(INPUTFILE))
    for i in 1:1000
        motion!(moons)
    end
    println("First half: $(sum(energy.(moons)))")
end

function getcycles(moons, axis)
    moons = copy.(moons)
    val = () -> [[m.position[axis] for m in moons]..., [m.velocity[axis] for m in moons]...]
    first = val()
    motion!(moons)
    λ = 1
    while val() != first
        motion!(moons)
        λ += 1
    end
    λ
end

let moons = Moon.(readlines(INPUTFILE))
    cycles = [getcycles(moons, i) for i in 1:3]
    println("Second half: $(lcm(cycles...))")
end

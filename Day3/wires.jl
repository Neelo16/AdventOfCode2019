using DataStructures: DefaultDict
using Base.Iterators: flatten

const INPUTFILE = joinpath(@__DIR__, "input.txt")

dist(p₁, p₂) = sum(abs.(p₁ - p₂))
distorigin(p) = dist([0, 0], p)

abstract type Movement end

struct Up <: Movement
    units::Int
end

struct Down <: Movement
    units::Int
end

struct Left <: Movement
    units::Int
end

struct Right <: Movement
    units::Int
end

struct Wire
    movements::Vector{Movement}
end

function Movement(s::AbstractString)
    dir = first(s)
    units = parse(Int, s[nextind(s, 1):end])
    dir == 'U' && return Up(units)
    dir == 'D' && return Down(units)
    dir == 'R' && return Right(units)
    dir == 'L' && return Left(units)
    error("Unrecognized direction $dir")
end

move(p, up::Up) = p + [0, up.units]
move(p, down::Down) = p - [0, down.units]
move(p, right::Right) = p + [right.units, 0]
move(p, left::Left) = p - [left.units, 0]

function Wire(input::String)
    movements = Movement.(split(input, ","))
    Wire(movements)
end

wires = Wire.(readlines(INPUTFILE))

board = DefaultDict(() -> DefaultDict(0))
intersections = Set()
steps =  DefaultDict(() -> DefaultDict(0))

for (i, wire) in enumerate(wires)
    next = [0, 0]
    stepcounter = 0
    for movement in wire.movements
        step = typeof(movement)(1)
        for _ in 1:movement.units
            next = move(next, step)
            stepcounter += 1
            x, y = next
            if board[x][y] ∉ [0, i]
                push!(intersections, next)
            end
            if board[x][y] ≠ i
                steps[x][y] += stepcounter # Repeated visits don't count
            end
            board[x][y] = i
        end
    end
end

println("First half: $(minimum(distorigin, intersections))")

let minsteps = Inf
    for point in intersections
        x, y = point
        minsteps = min(minsteps, steps[x][y])
    end
    println("Second half: $(Int(minsteps))")
end

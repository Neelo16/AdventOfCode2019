using DataStructures
using Intcode

const INPUTFILE = joinpath(@__DIR__, "input.txt")
inp = parse.(Int, split(read(INPUTFILE, String), ","))

struct Droid
    brain::Computer
    input::Channel{Int}
    output::Channel{Int}
end
function Droid(brain::Computer)
    droid = Droid(brain, Channel{Int}(1), Channel{Int}(1))
    defop!(droid.brain, OUTPUT_OPCODE, (v) -> put!(droid.output, v), 1, writemem=false)
    defop!(droid.brain, INPUT_OPCODE, () -> take!(droid.input), 1)
    Threads.@spawn runprogram!(droid.brain)
    droid
end

const WALL = 0
const EMPTY = 1
const OXYGEN = 2
const UNKNOWN = 3

inversedir(d::Int) = d + (iseven(d) ? -1 : 1)

function displaymaze(labyrinth::DefaultDict{Complex,Int}, path::Vector{Int})
    coordinates = keys(labyrinth)
    min_x, max_x = minimum(real.(coordinates)), maximum(real.(coordinates))
    min_y, max_y = minimum(imag.(coordinates)), maximum(imag.(coordinates))
    sprites = ['#', '.', 'O', ' ']
    println("-------")
    dronecoord = pathtocoord(path)
    for y in min_y:max_y
        for x in min_x:max_x
            pixel = labyrinth[Complex(x, y)]
            if Complex(x, y) == dronecoord
                print('D')
            else
                print(sprites[pixel+1])
            end
        end
        println()
    end
    println("-------")
end

function pathtocoord(p)
    dirs = [im, -im, -1, 1]
    start = 0
    for d in p
        start += dirs[d]
    end
    start
end

around(c) = c .+ [im, -im, -1, 1]

function maparea(droid::Droid, display::Bool=false)
    maze = DefaultDict{Complex, Int}(UNKNOWN)
    maze[0] = EMPTY
    queue = Queue{Vector{Int}}()
    for direction in 1:4
        enqueue!(queue, [direction])
    end
    shortestpath = []
    while !isempty(queue)
        next = dequeue!(queue)
        result = travel(droid, next)
        maze[pathtocoord(next)] = result
        if result == OXYGEN
            shortestpath = next
        end
        if result != WALL
            for direction in filter(d -> d != inversedir(next[end]), 1:4)
                enqueue!(queue, [next..., direction])
            end
        else
            pop!(next) # Since the droid didn't move, we can't backtrack this position
        end
        if display
            displaymaze(maze, next)
            sleep(1/60)
        end
        travel(droid, reverse(inversedir.(next)))
    end
    return maze, shortestpath
end

function travel(droid::Droid, path::Vector{Int})
    let out = -1
        for d in path
            put!(droid.input, d)
            out = take!(droid.output)
        end
        out
    end
end

function spreadoxygen(area::DefaultDict{Complex,Int}, start::Complex)
    minutes = 0
    unspreadoxygen = Queue{Complex}()
    enqueue!(unspreadoxygen, start)
    while any(t -> t == EMPTY, values(area))
        minutes += 1
        next = Queue{Complex}()
        while !isempty(unspreadoxygen)
            oxygen = dequeue!(unspreadoxygen)
            for c in around(oxygen)
                if area[c] == EMPTY
                    area[c] = OXYGEN
                    enqueue!(next, c)
                end
            end
        end
        unspreadoxygen = next
    end
    minutes
end

let droid = Droid(Computer(inp))
    area, shortestpath = maparea(droid)
    println("First half: $(length(shortestpath))")
    println("Second half: $(spreadoxygen(area, pathtocoord(shortestpath)))")
end

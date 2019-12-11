using DataStructures
using Intcode

const INPUTFILE = joinpath(@__DIR__, "input.txt")
inp = parse.(Int, split(read(INPUTFILE, String), ","))

const BLACK = 0
const WHITE = 1

function paint!(brain::Computer, startcolor=BLACK)
    ship = DefaultDict{Complex,Int}(0)
    direction = -im
    position = 0
    ship[position] = startcolor
    setstate! = (state) -> defop!(brain, OUTPUT_OPCODE, state, 1, writemem=false)
    paintingstate = (output) -> begin
        ship[position] = output
        setstate!(turningstate)
    end
    turningstate =  (output) -> begin
        direction *= output == 1 ? im : -im
        position += direction
        setstate!(paintingstate)
    end
    initialstate = paintingstate
    defop!(brain, INPUT_OPCODE, () -> ship[position], 1)
    setstate!(initialstate)
    runprogram!(brain)
    ship
end

function display_hull(ship::DefaultDict{Complex,Int})
    coordinates = keys(ship)
    min_x, max_x = minimum(real.(coordinates)), maximum(real.(coordinates))
    min_y, max_y = minimum(imag.(coordinates)), maximum(imag.(coordinates))
    for y in min_y:max_y
        for x in min_x:max_x
            pixel = ship[Complex(x, y)]
            print(pixel == WHITE ? '▩' : ' ')
        end
        println()
    end
end

let program = Computer(inp), ship = paint!(program, BLACK)
    println("First half: $(length(keys(ship)))")
end

let program = Computer(inp), ship = paint!(program, WHITE)
    println("Second half: ")
    display_hull(ship)
end

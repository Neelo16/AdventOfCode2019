using Intcode

const INPUTFILE = joinpath(@__DIR__, "input.txt")
const inp = parse.(Int, split(read(INPUTFILE, String), ","))

let computer = Computer(inp)
    defop!(computer, INPUT_OPCODE, () -> 1, 1)
    println("First half: ")
    runprogram!(computer)
end

let computer = Computer(inp)
    defop!(computer, INPUT_OPCODE, () -> 5, 1)
    println("Second half: ")
    runprogram!(computer)
end

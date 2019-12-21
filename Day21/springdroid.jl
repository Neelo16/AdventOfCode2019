using Intcode

const INPUTFILE = joinpath(@__DIR__, "input.txt")
const WALK = joinpath(@__DIR__, "walk.droidscript")
const RUN = joinpath(@__DIR__, "run.droidscript")
inp = parse.(Int, split(read(INPUTFILE, String), ","))

writeline(channel::Vector{Int}, line::AbstractString) = push!(channel, collect(line)..., '\n')

function programdrone(intcode::Vector{Int}, droidscriptpath::AbstractString)
    computer = Computer(intcode)
    program = Vector{Int}()
    send = (s) -> writeline(program, s)
    defop!(computer, OUTPUT_OPCODE, (v) -> v > 255 && println(v), 1, writemem=false)
    defop!(computer, INPUT_OPCODE, () -> popfirst!(program), 1)
    foreach(send, filter(!isempty, readlines(droidscriptpath)))
    runprogram!(computer)
end

let
    print("First half: ")
    programdrone(inp, WALK)
    print("Second half: ")
    programdrone(inp, RUN)
end

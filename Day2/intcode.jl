const INPUTFILE = joinpath(@__DIR__, "input.txt")
input = parse.(Int, split(read(INPUTFILE, String), ","))

function getop(opcode::Int)
    if opcode == 1
        +
    elseif opcode == 2
        *
    elseif opcode == 99
        :halt
    else
        error("Unexpected opcode $(opcode)")
    end
end

incr(x) = x+1

function runprogram(program::Vector{Int})
    for ip in 1:4:length(program)
        op = getop(program[ip])
        op == :halt && break
        a, b, dest = incr.(program[ip+1:ip+3]) # Input is zero-indexed, Julia is one-indexed
        program[dest] = op(program[a], program[b])
    end
    program
end

function prepare(program::Vector{Int}, noun::Int, verb::Int)
    alarm = copy(program)
    alarm[2] = noun
    alarm[3] = verb
    alarm
end

alarm = prepare(input, 12, 2)
println("First half: $(runprogram(alarm)[1])")

for (noun, verb) in Iterators.product(0:99, 0:99)
    tentative = prepare(input, noun, verb)
    runprogram(tentative)
    if tentative[1] == 19690720
        println("Second half: $(100 * noun + verb)")
        break
    end
end

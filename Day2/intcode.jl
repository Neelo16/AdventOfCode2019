const INPUTFILE = joinpath(@__DIR__, "input.txt")
input = parse.(Int, split(read(INPUTFILE, String), ","))

struct Instruction
    opcode::Int
    op
    size::Int
end

const instructions = Dict{Int, Instruction}()

function defop(val, op, size)
    instructions[val] = Instruction(val, op, size)
end

defop(1, +, 3)
defop(2, *, 3)
defop(99, :halt, 0)

valid_opcode(opcode) = opcode ∈ keys(instructions)

function fetch(opcode::Int)
    if valid_opcode(opcode)
        instructions[opcode]
    else
        error("Unexpected opcode $(opcode)")
    end
end

incr(x) = x+1

function runprogram!(program::Vector{Int})
    ip = 1
    while true
        instruction = fetch(program[ip])
        instruction.op == :halt && break
        args = incr.(program[ip+1:ip+instruction.size]) # Input is zero-indexed, Julia is one-indexed
        if length(args) > 1
            args, dest = args[1:end-1], args[end]
        elseif length(args) == 1
            args, dest = [], first(args)
        else
            instruction.op()
            @goto nextip
        end
        program[dest] = instruction.op([program[i] for i in args]...)
        @label nextip
        ip += 1 + instruction.size
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
println("First half: $(runprogram!(alarm)[1])")

for (noun, verb) in Iterators.product(0:99, 0:99)
    tentative = prepare(input, noun, verb)
    runprogram!(tentative)
    if tentative[1] == 19690720
        println("Second half: $(100 * noun + verb)")
        break
    end
end

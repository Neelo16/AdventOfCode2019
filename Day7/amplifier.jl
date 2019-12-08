const INPUTFILE = joinpath(@__DIR__, "input.txt")

const POSITION = 0
const IMMEDIATE = 1

struct Instruction
    opcode::Int
    op
    size::Int
    output::Bool
    jump::Bool
end

struct InstructionPointer
    ip::Int
end

const instructions = Dict{Int, Instruction}()

function defop(opcode::Int, op, size::Int, output=true; jump=false)
    instructions[opcode] = Instruction(opcode, op, size, output, jump)
end

function readinput()
    print("Input: ")
    parse(Int, readline(stdin))
end

defop(1, +, 3)
defop(2, *, 3)
defop(99, :halt, 0)

defop(3, readinput, 1)
defop(4, println, 1, false)

jumpiftrue(cond, value, ip) = cond != 0 ? value + 1 : ip
jumpiffalse(cond, value, ip) = cond == 0 ? value + 1 : ip
lessthan(args...)::Int = <(args...)
equals(args...)::Int = ==(args...)

defop(5, jumpiftrue, 2, jump=true)
defop(6, jumpiffalse, 2, jump=true)
defop(7, lessthan, 3)
defop(8, equals, 3)

getopcode(opcode::Int) = opcode % 100
valid_opcode(opcode) = opcode ∈ keys(instructions)

function getparametermodes(opcode::Int)
    instruction = fetch(opcode)
    digits(opcode, pad=instruction.size + 2)[3:end]
end

function getargvalues(parametermodes, args, program)
    values = []
    for (arg, mode) in zip(args, parametermodes)
        if mode == IMMEDIATE
            push!(values, arg)
        elseif mode == POSITION
            push!(values, program[arg + 1]) # Input is zero-indexed, Julia is one-indexed
        else
            error("Unrecognized parameter mode $mode")
        end
    end
    values
end

function fetch(instructioncode::Int)
    opcode = getopcode(instructioncode)
    if valid_opcode(opcode)
        instructions[opcode]
    else
        error("Unexpected opcode $(opcode)")
    end
end

function runprogram!(program::Vector{Int}, ip=1)
    while true
        instruction = fetch(program[ip])
        instruction.op == :halt && break
        args = program[ip+1:ip+instruction.size]
        argvalues = getargvalues(getparametermodes(program[ip]), args, program)
        if instruction.jump
            newip = instruction.op(argvalues..., ip)
            changed = newip != ip
            ip = newip
            changed && continue
        elseif instruction.output
            program[args[end] + 1] = instruction.op(argvalues[1:end-1]...)
        else
            instruction.op(argvalues...)
        end
        ip += 1 + instruction.size
    end
    program
end


program = parse.(Int, split(read(INPUTFILE, String), ","))

let maxoutput = -Inf
    for phases in Iterators.product(Iterators.repeated(0:4, 5)...)
        length(phases) != length(Set(phases)) && continue # We want combinations only
        output = 0
        defop(4, (v) -> output = v, 1, false)
        for phase in phases
            inputs = [phase, output]
            prog = copy(program)
            defop(3, () -> popfirst!(inputs), 1)
            runprogram!(prog)
        end
        maxoutput = max(maxoutput, output)
    end
    println("First half: $(Int(maxoutput))")
end

let maxoutput = -Inf
    for phases in Iterators.product(Iterators.repeated(5:9, 5)...)
        length(phases) != length(Set(phases)) && continue # We want combinations only
        output = 0
        defop(4, (v, ip) -> throw((v, ip)), 1, jump=true)
        done = false
        ips = [1 for _ in 1:length(phases)]
        progs = [copy(program) for _ in 1:length(phases)]
        inputs = [[phase] for phase in phases]
        push!(inputs[1], 0)
        while !done
            for (i, phase) in enumerate(phases)
                defop(3, () -> popfirst!(inputs[i]), 1)
                try
                    runprogram!(progs[i], ips[i])
                    done = i == length(phases)
                catch t
                    t isa Tuple || rethrow()
                    output, ip = t
                    ips[i] = ip + 2
                    push!(inputs[i % length(phases) + 1], output)
                end
            end
        end
        maxoutput = max(maxoutput, first(output))
    end
    println("Second half: $(Int(maxoutput))")
end

const INPUTFILE = joinpath(@__DIR__, "input.txt")

const POSITION = 0
const IMMEDIATE = 1
const RELATIVE = 2

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

defop(9, :newbase, 1)

getopcode(opcode::Int) = opcode % 100
valid_opcode(opcode) = opcode ∈ keys(instructions)

function getparametermodes(opcode::Int)
    instruction = fetch(opcode)
    digits(opcode, pad=instruction.size + 2)[3:end]
end

function getargvalues(parametermodes, args, program, base)
    values = []
    for (arg, mode) in zip(args, parametermodes)
        if mode == IMMEDIATE
            push!(values, arg)
        elseif mode == POSITION
            push!(values, program[arg + 1]) # Input is zero-indexed, Julia is one-indexed
        elseif mode == RELATIVE
            push!(values, program[base + arg])
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

function getoutputindex(parametermodes, args, base)
    outputmode, outputvalue = last.((parametermodes, args))
    if outputmode == POSITION
        outputvalue + 1
    elseif outputmode == RELATIVE
        base + outputvalue
    else
        error("Invalid parameter mode $outputmode")
    end
end

function runprogram!(program::Vector{Int})
    ip = 1
    base = 1
    while true
        instruction = fetch(program[ip])
        instruction.op == :halt && break
        args = program[ip+1:ip+instruction.size]
        parametermodes = getparametermodes(program[ip])
        argvalues = getargvalues(parametermodes, args, program, base)
        if instruction.op == :newbase
            base += first(argvalues)
        elseif instruction.jump
            newip = instruction.op(argvalues..., ip)
            changed = newip != ip
            ip = newip
            changed && continue
        elseif instruction.output
            program[getoutputindex(parametermodes, args, base)] = instruction.op(argvalues[1:end-1]...)
        else
            instruction.op(argvalues...)
        end
        ip += 1 + instruction.size
    end
    program
end

function creatememory(program::Vector{Int})
    memory = zeros(Int, length(program)*16)
    memory[1:length(inp)] = program
    memory
end

inp = parse.(Int, split(read(INPUTFILE, String), ","))

let program = creatememory(inp)
    defop(3, () -> 1, 1)
    println("First half: ")
    runprogram!(program)
end

let program = creatememory(inp)
    defop(3, () -> 2, 1)
    println("Second half: ")
    runprogram!(program)
end

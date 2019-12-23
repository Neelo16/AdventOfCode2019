module Intcode

export Computer, defop!, definput!, defoutput!,
 ADD_OPCODE,
 MUL_OPCODE,
 INPUT_OPCODE,
 OUTPUT_OPCODE,
 JUMPIFTRUE_OPCODE,
 JUMPIFFALSE_OPCODE,
 LESSTHAN_OPCOD,
 EQUALS_OPCODE,
 NEWBASE_OPCODE,
 HALT_OPCODE,
 runprogram!


const POSITION = 0
const IMMEDIATE = 1
const RELATIVE = 2

struct Instruction
    opcode::Int
    op
    size::Int
    writemem::Bool
    jump::Bool
end

mutable struct Computer
    memory::Vector{Int}
    instructions::Dict{Int, Instruction}
    ip::Int
    base::Int
end

function defop!(computer::Computer, opcode::Int, op, size::Int; writemem=true, jump=false)
    computer.instructions[opcode] = Instruction(opcode, op, size, writemem, jump)
end

function readinput()
    print("Input: ")
    parse(Int, readline(stdin))
end

const ADD_OPCODE = 1
const MUL_OPCODE = 2
const INPUT_OPCODE  = 3
const OUTPUT_OPCODE = 4
const JUMPIFTRUE_OPCODE = 5
const JUMPIFFALSE_OPCODE = 6
const LESSTHAN_OPCODE = 7
const EQUALS_OPCODE = 8
const NEWBASE_OPCODE = 9
const HALT_OPCODE = 99

jumpiftrue(cond, value) = cond != 0 ? value + 1 : :nojump
jumpiffalse(cond, value) = cond == 0 ? value + 1 : :nojump
lessthan(args...)::Int = <(args...)
equals(args...)::Int = ==(args...)

function reset_instructions!(computer::Computer)
    defop!(computer, ADD_OPCODE, +, 3)
    defop!(computer, MUL_OPCODE, *, 3)
    defop!(computer, HALT_OPCODE, :halt, 0)
    defop!(computer, INPUT_OPCODE, readinput, 1)
    defop!(computer, OUTPUT_OPCODE, println, 1, writemem=false)
    defop!(computer, JUMPIFTRUE_OPCODE, jumpiftrue, 2, jump=true)
    defop!(computer, JUMPIFFALSE_OPCODE, jumpiffalse, 2, jump=true)
    defop!(computer, LESSTHAN_OPCODE, lessthan, 3)
    defop!(computer, EQUALS_OPCODE, equals, 3)
    defop!(computer, NEWBASE_OPCODE, :newbase, 1)
end

defoutput!(computer::Computer, f) = defop!(computer, OUTPUT_OPCODE, f, 1, writemem=false)
definput!(computer::Computer, f) = defop!(computer, INPUT_OPCODE, f, 1)

getopcode(opcode::Int) = opcode % 100
valid_opcode(computer::Computer, opcode::Int) = opcode ∈ keys(computer.instructions)

function getparametermodes(computer)
    opcode = computer.memory[computer.ip]
    instruction = fetch(computer)
    digits(opcode, pad=instruction.size + 2)[3:end]
end

function getargvalues(parametermodes, args, computer)
    values = Vector(undef, length(args))
    for (i, (arg, mode)) in enumerate(zip(args, parametermodes))
        if mode == IMMEDIATE
            values[i] = arg
        elseif mode == POSITION
            values[i] = computer.memory[arg + 1] # Input is zero-indexed, Julia is one-indexed
        elseif mode == RELATIVE
            values[i] = computer.memory[computer.base + arg]
        else
            error("Unrecognized parameter mode $mode")
        end
    end
    values
end

function fetch(computer::Computer)
    instructioncode = computer.memory[computer.ip]
    opcode = getopcode(instructioncode)
    if valid_opcode(computer, opcode)
        computer.instructions[opcode]
    else
        error("Unexpected opcode $(opcode)")
    end
end

function getoutputindex(parametermodes, args, computer)
    outputmode, outputvalue = last.((parametermodes, args))
    if outputmode == POSITION
        outputvalue + 1
    elseif outputmode == RELATIVE
        computer.base + outputvalue
    else
        error("Invalid parameter mode $outputmode")
    end
end

function runprogram!(computer::Computer)
    while true
        instruction = fetch(computer)
        instruction.op == :halt && break
        args = computer.memory[computer.ip+1:computer.ip+instruction.size]
        parametermodes = getparametermodes(computer)
        argvalues = getargvalues(parametermodes, args, computer)
        if instruction.op == :newbase
            computer.base += first(argvalues)
        elseif instruction.jump
            newip = instruction.op(argvalues...)
            if newip != :nojump
                computer.ip = newip
                continue
            end
        elseif instruction.writemem
            computer.memory[getoutputindex(parametermodes, args, computer)] = instruction.op(argvalues[1:end-1]...)
        else
            instruction.op(argvalues...)
        end
        computer.ip += 1 + instruction.size
    end
    computer
end

function Computer(program::Vector{Int})
    memory = zeros(Int, length(program)*16)
    copyto!(memory, program)
    computer = Computer(memory, Dict(), 1, 1)
    reset_instructions!(computer)
    computer
end

end # module

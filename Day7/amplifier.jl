using Intcode

const INPUTFILE = joinpath(@__DIR__, "input.txt")

const inp = parse.(Int, split(read(INPUTFILE, String), ","))

alldiff(itr) = length(itr) == length(Set(itr))

let maxoutput = typemin(Int)
    for phases in Iterators.product(Iterators.repeated(0:4, 5)...)
        alldiff(phases) || continue # We want combinations only
        output = 0
        for phase in phases
            inputs = [output, phase]
            computer = Computer(inp)
            defop!(computer, INPUT_OPCODE, () -> pop!(inputs), 1)
            defop!(computer, OUTPUT_OPCODE, (v) -> output = v, 1, writemem=false)
            runprogram!(computer)
        end
        maxoutput = max(maxoutput, output)
    end
    println("First half: $(maxoutput)")
end

let maxoutput = typemin(Int)
    for phases in Iterators.product(Iterators.repeated(5:9, 5)...)
        alldiff(phases) || continue # We want combinations only
        channels = [Channel(2) for _ in 1:length(phases)]
        @sync for (i, phase) in enumerate(phases)
            computer = Computer(inp)
            defop!(computer, OUTPUT_OPCODE, (v) -> put!(channels[i % length(phases) + 1], v), 1, writemem=false)
            defop!(computer, INPUT_OPCODE, () -> take!(channels[i]), 1)
            put!(channels[i], phase)
            i == 1 && put!(channels[i], 0)
            @async runprogram!(computer)
        end
        output = take!(first(channels))
        maxoutput = max(maxoutput, output)
    end
    println("Second half: $(Int(maxoutput))")
end

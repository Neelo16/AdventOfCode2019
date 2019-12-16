using Base.Iterators: take, cycle, drop

const INPUTFILE = joinpath(@__DIR__, "input.txt")

inp = parse.(Int, collect(chomp(read(INPUTFILE, String))))

const base = [0, 1, 0, -1]

pattern(base, phase, size) = collect(take(drop(cycle(repeat(base, inner=phase)), 1), size))

function cleansignal(signal, nphases, base)
    output = Vector{Int}(undef, length(signal))
    for phase in 1:nphases
        for i in 1:length(output)
            output[i] = abs(signal' * pattern(base, i, length(signal))) % 10
        end
        signal = copy(output)
    end
    output
end

println("First half: ", cleansignal(inp, 100, base)[1:8]...)

fromdigits(dig) = reduce((n, n2) -> 10*n + n2, dig)

function fastclean(signal, nphases)
    signal = reverse(signal)
    for _ in 1:nphases
        signal = cumsum(signal) .% 10
    end
    reverse!(signal)
end

let offset = fromdigits(inp[1:7]), signal = repeat(inp, 10000)[offset+1:end]
    # After the halfway point, each digit is the result of summing all subsequent digits
    println("Second half: ", fastclean(signal, 100)[1:8]...)
end

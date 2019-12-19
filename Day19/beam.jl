using Intcode

const INPUTFILE = joinpath(@__DIR__, "input.txt")
inp = parse.(Int, split(read(INPUTFILE, String), ","))

const Point = Tuple{Int,Int}

function isbeam(program, point)::Bool
    computer = Computer(program)
    input = collect(reverse(point))
    output = false
    defop!(computer, OUTPUT_OPCODE, v -> output = v, 1, writemem=false)
    defop!(computer, INPUT_OPCODE, () -> pop!(input), 1)
    runprogram!(computer)
    output
end

function mapbeam(program, xmax=49, ymax=49)
    beam = Dict{Point,Bool}()
    for point in Iterators.product(0:xmax, 0:ymax)
        beam[point] = isbeam(program, point)
    end
    beam
end

function findsquare(program, side=100; display=false)
    initialbeam = mapbeam(program)
    xvalues = sort(collect(Set(first.(keys(initialbeam)))))
    yvalues = sort(collect(Set(last.(keys(initialbeam)))))
    starty = 0
    for y in yvalues
        # If there are less than 3 grid units, they may be
        # disjointed.
        if count(initialbeam[x, y] for x in xvalues) > 2
            starty = y
            break
        end
    end
    bottomx = findfirst(x -> initialbeam[x, starty], xvalues)
    topx = findlast(x -> initialbeam[x, starty], xvalues)
    bottom = (xvalues[bottomx], starty)
    top = (xvalues[topx], starty)
    for _ in 1:side-1
        bottom = stepbottom(program, bottom)
    end
    while top[1] - bottom[1] != side - 1
        bottom = stepbottom(program, bottom)
        top = steptop(program, top)
    end
    display && displaybeam(program, top, bottom, side)
    (bottom[1], top[2])
end

function stepbottom(program, pos::Point)
    pos = pos .+ (0, 1)
    while !isbeam(program, pos)
        pos = pos .+ (1, 0)
    end
    pos
end

function steptop(program, pos::Point)
    pos = pos .+ (0, 1)
    while isbeam(program, pos)
        pos = pos .+ (1, 0)
    end
    pos .- (1, 0)
end

function displaybeam(program, top, bottom, side)
    xmax = max(top[1], bottom[1])
    ymax = max(top[2], bottom[2])
    io = IOBuffer()
    for y in max(0, ymax-(side + side ÷ 2)):ymax
        for x in max(0, xmax - (side + side ÷ 2)):xmax
            if (x, y) ∈ (top, bottom)
                write(io, 'X')
            else
                write(io, isbeam(program, (x, y)) ? '#' : '.')
            end
        end
        write(io, '\n')
    end
    print(String(take!(io)))
end

let beam = mapbeam(inp)
    println("First half: $(count(values(beam)))")
end

let squareloc = findsquare(inp)
    println("Second half: $(squareloc[1]*10000 + squareloc[2])")
end

using Intcode

const INPUTFILE = joinpath(@__DIR__, "input.txt")
inp = parse.(Int, split(read(INPUTFILE, String), ","))

const SCAFFOLD = '#'
const EMPTY = '.'
const INTERSECTION = 'O'
const ROBOT = "v<^>"

isscaffold(c) = c == SCAFFOLD
isemptyspace(c) = c == EMPTY
isintersection(c) = c == INTERSECTION
isvalidpath(c) = isscaffold(c) || isintersection(c)
isrobot(c) = c ∈ ROBOT

robotdir(r) = im^findfirst(c -> c == r, ROBOT)

function getview(program)
    view = Dict{Complex,Char}()
    coord = 0
    getoutput = (out) -> begin
        if out == 10
            coord = (imag(coord)+1)im
        else
            view[coord] = Char(out)
            coord += 1
        end
    end
    computer = Computer(program)
    defop!(computer, OUTPUT_OPCODE, getoutput, 1, writemem=false)
    runprogram!(computer)
    view
end

function showview(view)
    for y in 0:height(view)
        for x in 0:width(view)
            print(view[Complex(x, y)])
        end
        println()
    end
end

width(view) = maximum(real.(keys(view)))
height(view) = maximum(imag.(keys(view)))

function intersections!(view)
    parameters = 0
    for coord in keys(view)
        if isvalidpath(view[coord]) && count(c -> isscaffold(view[c]), around(coord, view)) == 4
            parameters += real(coord) * imag(coord)
            view[coord] = INTERSECTION
        end
    end
    parameters
end

function around(coord, view)
    neighbors = [coord + im^i for i in 0:3]
    [neighbor for neighbor in neighbors if neighbor ∈ keys(view)]
end

asciirot(c) = c == im ? 'R' : 'L'

function calcpath!(view)
    intersections!(view)
    robot = first(k for (k, v) in view if isrobot(v))
    path = []
    dir = robotdir(view[robot])
    rotation = im
    while any(isvalidpath, values(view))
        validpos = filter(c -> isvalidpath(view[c]), around(robot, view))
        if isempty(validpos) # Robot is standing on the final scaffold
            view[robot] = EMPTY
            break
        end
        if robot + rotation*dir ∉ validpos
            rotation *= -1
        end
        dir *= rotation
        steps = 0
        nextpos = robot + dir
        while nextpos ∈ keys(view) && isvalidpath(view[nextpos])
            if isintersection(view[robot])
                view[robot] = SCAFFOLD
            else
                view[robot] = EMPTY
            end
            robot = nextpos
            steps += 1
            nextpos += dir
        end
        push!(path, asciirot(rotation), string(steps))
    end
    join(path, ',')
end

function rescuerobots!(program, view)
    path = calcpath!(view)
    main, routines = simplify(path)
    camera = "n"
    input = []
    for line in (main, routines..., camera)
        push!(input, string(line, '\n')...)
    end
    reverse!(input)
    c = Computer(inp)
    output = -1111
    defop!(c, OUTPUT_OPCODE, (v) -> output = v, 1, writemem=false)
    defop!(c, INPUT_OPCODE, () -> Int(pop!(input)), 1)
    c.memory[1] = 2
    runprogram!(c)
    output
end

function simplify(path::AbstractString)
    patterns = getpatterns(path)
    for (name, pattern) in patterns
        path = replace(path, pattern => name)
    end
    path, getindex.(patterns, 2)
end

function getpatterns(path::AbstractString, nroutines::Int=3, sizelimit::Int=20)
    pnames = string('A':'A'+nroutines...)
    # e.g. regex for 3 routines (A, B and C): ^[ABC,]+
    # used to remove leading pattern names and commas from the path
    cleanregex = Regex("^[$(join(pnames, '|')),]+")
    clean = (s) -> replace(s, cleanregex => "")
    for psizes in Iterators.product(Iterators.repeated(1:sizelimit, nroutines)...)
        simplified = path
        patterns = []
        for (name, psize) in zip(pnames, psizes)
            pattern = simplified[1:psize]
            # Patterns can't mention other patterns
            pattern = first(split(pattern, Regex("($(join(pnames, '|')))")))
            push!(patterns, name => pattern)
            simplified = clean(replace(simplified, pattern => name))
            simplified == "" && return patterns
        end
    end
    return nothing
end

let view = getview(inp)
    println("First half: $(intersections!(view))")
    println("Second half: $(rescuerobots!(inp, view))")
end

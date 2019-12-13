using Intcode

const INPUTFILE = joinpath(@__DIR__, "input.txt")
inp = parse.(Int, split(read(INPUTFILE, String), ","))

const Point = Tuple{Int,Int}

function initrender(computer::Computer)
    screen = Dict{Point, Int}()
    coord = []
    global score = Threads.Atomic{Int}(0)
    global needinput = false
    global inputlock = Threads.Condition()
    global input = Channel()
    setstate! = (state) -> defop!(computer, OUTPUT_OPCODE, state, 1, writemem=false)
    coord_state = (x) -> begin
        push!(coord, x)
        length(coord) == 2 && setstate!(id_state)
    end
    id_state = (x) -> begin
        if coord == [-1, 0]
            score[] = x
        else
            screen[Point(coord)] = x
        end
        empty!(coord)
        setstate!(coord_state)
    end
    setstate!(coord_state)
    readjoystick = () -> begin
        lock(inputlock)
        try
            needinput = true
            notify(inputlock)
        finally
            unlock(inputlock)
        end
        take!(input)
    end
    defop!(computer, INPUT_OPCODE, readjoystick, 1)
    screen
end

function displayscreen(screen)
    tiles = ['.', '#', 'B', '_', 'O']
    for y in 0:height(screen)
        for x in 0:width(screen)
            print(tiles[screen[x, y]+1])
        end
        println()
    end
    println("Score: $(score[])")
end

isemptyspace(x) = x == 0
isblock(x) = x == 2
ispaddle(x) = x == 3
isball(x) = x == 4

width(screen) = max(getindex.(keys(screen), 1)...)
height(screen) = max(getindex.(keys(screen), 2)...)

function play!(computer::Computer, screen)
    game = Threads.@spawn runprogram!(computer)
    ball = (0, 0)
    prevball = (0, 0)
    paddle = (0, 0)
    while !istaskdone(game)
        lock(inputlock)
        try
            while !needinput
                wait(inputlock)
            end
        finally
            unlock(inputlock)
        end
        for (k, v) in screen
            if isball(v)
                ball = k
            elseif ispaddle(v)
                paddle = k
            end
        end
        balldir = sign.(ball .- prevball)
        prevball = ball
        nextball = ball .+ balldir
        if ispaddle(screen[ball[1], nextball[2]])
            paddledir = 0
        else
            paddledir = sign(nextball[1] - paddle[1])
        end
        put!(input, paddledir)
    end
    displayscreen(screen)
    println("Game Over")
end

let computer = Computer(inp)
    screen = initrender(computer)
    runprogram!(computer)
    nblocks = count(isblock, values(screen))
    println("First half: $(nblocks)")
end

let
    inp[1] = 2
    computer = Computer(inp)
    screen = initrender(computer)
    play!(computer, screen)
end

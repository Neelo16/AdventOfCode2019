using DataStructures

const INPUTFILE = joinpath(@__DIR__, "input.txt")

struct State
    position::Complex
    keyset::Set{Char}
end
Base.:(==)(s₁::State, s₂::State) = s₁.position == s₂.position && s₁.keyset == s₂.keyset
Base.hash(s::State, h::UInt) = hash(s.position, hash(s.keyset, h))

const PLAYER = '@'
const WALL = '#'
const EMPTY = '.'

iskey(c)  = isletter(c) && islowercase(c)
isdoor(c) = isletter(c) && isuppercase(c)
iswall(c) = c == WALL
isemptyspace(c) = c == EMPTY
isplayer(c) = c == PLAYER
isrelevant(c) = isplayer(c) || isdoor(c) || iskey(c)
opens(key, door) = key == lowercase(door) && door == uppercase(key)
keyfor(door) = lowercase(door)

function parseinput(path)
    vault = Dict{Complex,Char}()
    positions = Dict{Char,Complex}()
    pos = 0
    for line in readlines(path)
        for c in line
            vault[pos] = c
            if isrelevant(c)
                if isplayer(c)
                    vault[pos] = EMPTY
                end
                positions[c] = pos
            end
            pos += 1
        end
        pos = (imag(pos) + 1)im
    end
    vault, positions
end

function reachable(vault, state::State)
    queue = Queue{Pair{Complex,Int}}()
    visited = DefaultDict{Complex,Bool}(false)
    enqueue!(queue, state.position => 0)
    distances = []
    while !isempty(queue)
        pos, dist = dequeue!(queue)
        e = vault[pos]
        visited[pos] = true
        if iswall(e) || (isdoor(e) && keyfor(e) ∉ state.keyset)
            continue
        end
        if iskey(e) && e ∉ state.keyset
            push!(distances, e => dist)
            continue
        end
        for nextpos in filter(c -> c ∈ keys(vault) && !visited[c], around(pos))
            enqueue!(queue, nextpos => dist+1)
        end
    end
    distances
end

around(pos) = [pos + im^α for α in 0:3]

function neighbors(vault, positions, state::State)
    keys = reachable(vault, state)
    [State(positions[key], Set([state.keyset..., key])) => dist for (key, dist) in keys]
end

function shortestpath(vault, positions, initialpos=positions[PLAYER], keys=filter(iskey, Base.keys(positions)))
    visited = Dict{State,Int}()
    unvisited = PriorityQueue{State,Int}()
    initialstate = State(initialpos, Set())
    enqueue!(unvisited, initialstate, 0)
    nkeys = length(keys)
    while true
        current, currentdist = peek(unvisited)
        if length(current.keyset) == nkeys
            return currentdist
        end
        dequeue!(unvisited)
        for (neighbor, dist) in filter(e -> e[1] ∉ Base.keys(visited), neighbors(vault, positions, current))
            neighbor ∉ Base.keys(unvisited) && enqueue!(unvisited, neighbor, typemax(Int))
            unvisited[neighbor] = min(unvisited[neighbor], currentdist + dist)
        end
        visited[current] = currentdist
    end
end

let (vault, positions) = parseinput(INPUTFILE)
    println("First half: $(shortestpath(vault, positions))")
end


function splitvault(vault, playerpos)
    vault[playerpos] = WALL
    for pos in around(playerpos)
        vault[pos] = WALL
    end
    [playerpos + (1+im)im^α for α in 0:3]
end

function keysanddoors(vault, pos, visited=DefaultDict{Complex,Bool}(false))
    visited[pos] = true
    current = []
    e = vault[pos]
    iswall(e) && return []
    if isdoor(e) || iskey(e)
        push!(current, [e])
    end
    for next in filter(c -> c ∈ keys(vault) && !visited[c], around(pos))
        push!(current, keysanddoors(vault, next, visited))
    end
    [Iterators.flatten(current)...]
end

let (vault, positions) = parseinput(INPUTFILE)
    entrances = splitvault(vault, positions[PLAYER])
    keys = []
    for (i, entrance) in enumerate(entrances)
        kd = keysanddoors(vault, entrance)
        push!(keys, filter(iskey, kd))
        doors = filter(isdoor, kd)
        for door in doors
            if keyfor(door) ∉ keys[i]
                # This robot can wait for some other robot to open the door
                # before it moves
                vault[positions[door]] = EMPTY
            end
        end
    end
    steps = zeros(Int, length(entrances))
    Threads.@threads for i in 1:length(entrances)
        steps[i] = shortestpath(vault, positions, entrances[i], keys[i])
    end
    println("Second half: $(sum(steps))")
end

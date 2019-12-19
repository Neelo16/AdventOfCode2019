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
    tunnel = Dict{Complex,Char}()
    positions = Dict{Char,Complex}()
    pos = 0
    for line in readlines(path)
        for c in line
            tunnel[pos] = c
            if isrelevant(c)
                if isplayer(c)
                    tunnel[pos] = EMPTY
                end
                positions[c] = pos
            end
            pos += 1
        end
        pos = (imag(pos) + 1)im
    end
    tunnel, positions
end

const reachablecache = Dict{State, Vector{Pair{Char,Int}}}()

function reachable(tunnel, state::State)
    if state ∈ keys(reachablecache)
        return reachablecache[state]
    end
    queue = Queue{Pair{Complex,Int}}()
    visited = DefaultDict{Complex,Bool}(false)
    enqueue!(queue, state.position => 0)
    distances = []
    while !isempty(queue)
        pos, dist = dequeue!(queue)
        e = tunnel[pos]
        visited[pos] = true
        if iswall(e) || (isdoor(e) && keyfor(e) ∉ state.keyset)
            continue
        end
        if iskey(e) && e ∉ state.keyset
            push!(distances, e => dist)
            continue
        end
        for nextpos in filter(c -> c ∈ keys(tunnel) && !visited[c], around(pos))
            enqueue!(queue, nextpos => dist+1)
        end
    end
    reachablecache[state] = distances
end

around(pos) = [pos + im^α for α in 0:3]

function neighbors(tunnel, positions, state::State)
    keys = reachable(tunnel, state)
    [State(positions[key], Set([state.keyset..., key])) => dist for (key, dist) in keys]
end

function shortestpath(tunnel, positions)
    visited = Dict{State,Int}()
    unvisited = PriorityQueue{State,Int}()
    initialstate = State(positions[PLAYER], Set())
    enqueue!(unvisited, initialstate, 0)
    nkeys = count(iskey, keys(positions))
    while true
        current, currentdist = peek(unvisited)
        if length(current.keyset) == nkeys
            return currentdist
        end
        dequeue!(unvisited)
        for (neighbor, dist) in filter(e -> e[1] ∉ keys(visited), neighbors(tunnel, positions, current))
            neighbor ∉ keys(unvisited) && enqueue!(unvisited, neighbor, typemax(Int))
            unvisited[neighbor] = min(unvisited[neighbor], currentdist + dist)
        end
        visited[current] = currentdist
    end
end

let (tunnel, positions) = parseinput(INPUTFILE)
    println("First half: $(shortestpath(tunnel, positions))")
end

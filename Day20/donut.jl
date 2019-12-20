using DataStructures

const INPUTFILE = joinpath(@__DIR__, "input.txt")

const WALL = '#'
const EMPTY = '.'

around(pos) = [pos + im^α for α in 0:3]

abstract type AbstractEdge end

mutable struct Vertex
    coord::Complex
    neighbors::Vector{AbstractEdge}
    visited::DefaultDict{Int,Bool}
    distance::DefaultDict{Int,Int}
end
Vertex(coord::Complex) = Vertex(coord, [], DefaultDict{Int,Bool}(false), DefaultDict{Int,Int}(typemax(Int)))

struct Edge <: AbstractEdge
    src::Vertex
    dst::Vertex
    isportal::Bool
    isinner::Bool
end
Edge(src, dst; isportal=false, isinner=false) = Edge(src, dst, isportal || isinner, isinner)

iswall(c) = c == WALL
istraversable(c) = c == EMPTY
isportal(c) = isletter(c)

function parseinput(path)
    maze = Dict{Complex,Char}()
    for (y, line) in enumerate(readlines(path))
        for (x, c) in enumerate(line)
            maze[Complex(x, y)] = c
        end
    end
    firstmazeline = sort(filter(i -> imag(i) == 3, collect(keys(maze))), by=real)
    llimit = real(firstmazeline[findfirst(c -> iswall(maze[c]), firstmazeline)])
    rlimit = real(firstmazeline[findlast(c -> iswall(maze[c]), firstmazeline)])
    ulimit = 3
    dlimit = maximum(imag.(keys(maze))) - 3
    graph = Dict{Complex,Vertex}()
    portals = Dict{String,Complex}()
    for (coord₁, value) in maze
        istraversable(value) || continue
        graph[coord₁] = Vertex(coord₁)
        for coord₂ in filter(c -> c ∈ keys(graph) || (c ∈ keys(maze) && isportal(maze[c])), around(coord₁))
            if isportal(maze[coord₂])
                label = getlabel(maze, coord₂)
                if label ∈ keys(portals)
                    isinner = llimit < real(coord₂) < rlimit && ulimit < imag(coord₂) < dlimit
                    coord₂ = portals[label]
                    push!(graph[coord₂].neighbors, Edge(graph[coord₂], graph[coord₁], isportal=true, isinner=!isinner))
                    push!(graph[coord₁].neighbors, Edge(graph[coord₁], graph[coord₂], isportal=true, isinner=isinner))
                else
                    portals[label] = first(filter(c -> c ∈ keys(maze) && istraversable(maze[c]), around(coord₂)))
                    continue
                end
            else
                push!(graph[coord₂].neighbors, Edge(graph[coord₂], graph[coord₁]))
                push!(graph[coord₁].neighbors, Edge(graph[coord₁], graph[coord₂]))
            end
        end
    end
    graph, portals["AA"], portals["ZZ"]
end

function getlabel(maze, coord)
    for coord₂ in (coord + im, coord + 1)
        if coord₂ ∈ keys(maze) && isportal(maze[coord₂])
            return string(maze[coord], maze[coord₂])
        end
    end
    for coord₂ in (coord - im, coord - 1)
        if coord₂ ∈ keys(maze) && isportal(maze[coord₂])
            return string(maze[coord₂], maze[coord])
        end
    end
end

function shortestpath(graph, src, dst, recursion=false, dstlevel=0)
    queue = Queue{Pair{Vertex,Int}}() # vertex => recursion level
    for v in values(graph)
        empty!(v.visited)
        empty!(v.distance)
    end
    enqueue!(queue, graph[src] => 0)
    graph[src].distance[0] = 0
    while !isempty(queue)
        v, level = dequeue!(queue)
        v.visited[level] = true
        if level == dstlevel && v.coord == dst
            return v.distance[level]
        end
        for e in v.neighbors
            curlevel = level
            if recursion && e.isportal
                if level == 0 && !e.isinner
                    continue
                end
                curlevel += e.isinner ? 1 : -1
            end
            v₂ = e.dst
            if !v₂.visited[curlevel]
                v₂.distance[curlevel] = v.distance[level] + 1
                enqueue!(queue, v₂ => curlevel)
            end
        end
    end
    error("Destination $dst not found")
end

let (graph, src, dst) = parseinput(INPUTFILE)
    println("First half: $(shortestpath(graph, src, dst))")
    println("Second half: $(shortestpath(graph, src, dst, true))")
end

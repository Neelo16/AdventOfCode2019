using Intcode

const INPUTFILE = joinpath(@__DIR__, "input.txt")
inp = parse.(Int, split(read(INPUTFILE, String), ","))

function startnetwork(program, ncomputers::Int, natmanager=false)
    tasks = Vector{Task}(undef, ncomputers)
    locks = Vector{Base.AbstractLock}(undef, ncomputers)
    inputs = Vector{Vector{Int}}(undef, ncomputers)
    idle = Vector{Int}(undef, ncomputers)
    idlelock = Condition()
    NATADDR = 255
    natpacketlock = ReentrantLock()
    natpackets = []
    previouspacket = (-1, -1)
    for i in 1:ncomputers
        locks[i] = ReentrantLock()
        inputs[i] = []
        idle[i] = 0
    end
    for i in 1:ncomputers
        computer = Computer(program)
        addr = 0
        boot = () -> begin
            definput!(computer, readx)
            return i - 1
        end
        startcomm = (newaddr) -> begin
            addr = newaddr + 1
            lock(idlelock)
            idle[:] .= 0
            unlock(idlelock)
            if addr == NATADDR + 1
                addr
                lock(natpacketlock)
            else
                lock(locks[addr])
            end
            defoutput!(computer, writex)
        end
        writex = (x) -> begin
            if addr == NATADDR + 1
                x
                push!(natpackets, x)
            else
                push!(inputs[addr], x)
            end
            defoutput!(computer, writey)
        end
        writey = (y) -> begin
            if addr == NATADDR + 1
                y
                push!(natpackets, y)
                unlock(natpacketlock)
            else
                push!(inputs[addr], y)
                unlock(locks[addr])
            end
            defoutput!(computer, startcomm)
        end
        readx = () -> begin
            lock(locks[i])
            lock(idlelock)
            if isempty(inputs[i])
                idle[i] = idle[i] == 0 ? 1 : 2
            else
                idle[:] .= 0
            end
            notify(idlelock)
            unlock(idlelock)
            if isempty(inputs[i])
                unlock(locks[i])
                yield()
                return -1
            else
                definput!(computer, read_y)
                return popfirst!(inputs[i])
            end
        end
        read_y = () -> begin
            val = popfirst!(inputs[i])
            unlock(locks[i])
            definput!(computer, readx)
            return val
        end
        definput!(computer, boot)
        defoutput!(computer, startcomm)
        tasks[i] = @async runprogram!(computer)
    end

    while true
        lock(idlelock)
        foo = 0
        while !all(==(2), idle)
            foo += 1
            wait(idlelock)
        end
        curpacket = ()
        lock(natpacketlock)
        try
            while !isempty(natpackets)
                curpacket = (popfirst!(natpackets), popfirst!(natpackets))
                !natmanager && return curpacket[2]
            end
        finally
            unlock(natpacketlock)
        end
        curpacket == previouspacket && return curpacket[2]
        previouspacket = curpacket
        lock(locks[1])
        push!(inputs[1], curpacket...)
        unlock(locks[1])
        idle[:] .= false
        unlock(idlelock)
    end

    return lastpackety
end

let
    println("First half: $(startnetwork(inp, 50))")
    println("Second half: $(startnetwork(inp, 50, true))")
end

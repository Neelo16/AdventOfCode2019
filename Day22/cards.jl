const NEWDECK = collect(0:10006)
const INPUTFILE = joinpath(@__DIR__, "input.txt")

deal(d) = reverse(d)

function cut(d, n)
    if n < 0
        n = length(d) + n
    end
    [Iterators.drop(d, n)..., Iterators.take(d, n)...]
end

function deal(d::Vector{T}, n) where T
    d₂ = Vector{T}(undef, length(d))
    for (i, c) in enumerate(d)
        d₂[(i-1)*n % length(d₂) + 1] = c
    end
    d₂
end

function parseinput(path::AbstractString, initialdeck, rev=false)
    deck = initialdeck
    for line in readlines(path)
        if startswith(line, "deal with increment")
            deck = deal(deck, parse(Int, last(split(line, ' '))))
        elseif startswith(line, "cut")
            deck = cut(deck, parse(Int, last(split(line, ' '))))
        elseif line == "deal into new stack"
            deck = deal(deck)
        else
            error("Unsupported operation requested: $line")
        end
    end
    deck
end

let deck = parseinput(INPUTFILE, NEWDECK)
    println("First half: $(findfirst(==(2019), deck) - 1)")
end

cuti(len, n, i) = mod(-n + i, len)
deali(len, i) = mod(-i - 1, len)
deali(len, n, i) = mod(i*n, len)

cuti⁻¹(len, n, i) = mod(n + i, len)
deali⁻¹(len, i) = deali(len, i)
deali⁻¹(len, n, i) = mod(i * invmod(n, len), len)

function getconstants(path::AbstractString, λ)
    a, b = 1, 0
    for line in reverse(readlines(path))
        if startswith(line, "cut")
            n = mod(parse(BigInt, last(split(line, ' '))), λ)
            b = mod(b + n, λ)
        elseif line == "deal into new stack"
            a = mod(-a, λ)
            b = mod(-b - 1, λ)
        elseif startswith(line, "deal with increment")
            n = mod(parse(BigInt, last(split(line, ' '))), λ)
            a = mod(invmod(n, λ) * a, λ)
            b = mod(invmod(n, λ) * b, λ)
        else
            error("Unsupported operation requested: $line")
        end
    end
    a, b
end

let deck = NEWDECK, index = 2020, decksize = 119315717514047, shuffles = 101741582076661
    a, b = getconstants(INPUTFILE, decksize)
    aᴷ = powermod(a, shuffles, decksize)
    bᴷ = b * (aᴷ - 1) * invmod(a - 1, decksize)
    println("Second half: $(mod(aᴷ*index + bᴷ, decksize))")
end

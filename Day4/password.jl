const INPUT = 145852:616942

validpassword(pw::AbstractString) = issorted(pw) && hasadjacentdigits(pw)
validpassword(pw::Int) = validpassword(string(pw))

function hasadjacentdigits(pw)
    if length(pw) < 2
        false
    else
        pw[1] == pw[2] || hasadjacentdigits(pw[2:end])
    end
end

println("First half: $(length(filter(validpassword, INPUT)))")

function haslessadjacentdigits(pw)
    if length(pw) < 2
        false
    else
        matches, rest = extractrepeated(pw)
        length(matches) == 2 || haslessadjacentdigits(rest)
    end
end

function extractrepeated(pw::AbstractString)
    if isempty(pw)
        nothing, nothing
    elseif length(pw) < 2
        first(pw), nothing
    else
        i = nextind(pw, 1)
        while pw[i] == pw[1] && i < length(pw)
            i = nextind(pw, i)
        end
        if i == length(pw) && pw[end] == pw[1]
            i += 1
        end
        pw[1:prevind(pw, i)], pw[i:end]
    end
end

hardervalidation(pw::AbstractString) = issorted(pw) && haslessadjacentdigits(pw)
hardervalidation(pw::Int) = hardervalidation(string(pw))

println("Second half: $(length(filter(hardervalidation, INPUT)))")

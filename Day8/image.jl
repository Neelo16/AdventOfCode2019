const INPUTFILE = joinpath(@__DIR__, "input.txt")

const IMAGE_WIDTH = 25
const IMAGE_HEIGHT = 6

pixels = parse.(Int, split(chomp(read(INPUTFILE, String)), ""))

layers = collect(Iterators.partition(pixels, IMAGE_WIDTH * IMAGE_HEIGHT))

istwo(x) = x == 2

let mincount = typemax(Int), minlayer = nothing
    for layer in layers
        zerocount = count(iszero, layer)
        if zerocount < mincount
            mincount = zerocount
            minlayer = layer
        end
    end
    println("First half: $(count(isone, minlayer) * count(istwo, minlayer))")
end

let image = copy(layers[end])
    for layer in layers[end-1:-1:1]
        for (i, color) in enumerate(layer)
            if color != 2
                image[i] = color
            end
        end
    end
    println("Second half:")
    for line in Iterators.partition(image, IMAGE_WIDTH)
        for pixel in line
            print(pixel == 1 ? '▩' : ' ')
        end
        println()
    end
end

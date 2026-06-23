local sprites = {}
local registry = {}

local TILE_SIZE = 16

local spriteOrder = { "wall", "open", "ladder", "spawner", "adventurer", "monster" }

function sprites.load()
    local data = love.image.newImageData("sprites.png")

    data:mapPixel(function(x, y, r, g, b, a)
        if r == 1 and g == 0 and b == 1 then
            return 0, 0, 0, 0
        end
        return r, g, b, a
    end)

    local image = love.graphics.newImage(data)

    for i, name in ipairs(spriteOrder) do
        local quad = love.graphics.newQuad(
            (i - 1) * TILE_SIZE, 0,
            TILE_SIZE, TILE_SIZE,
            image:getDimensions()
        )
        registry[name] = { image = image, quad = quad }
    end
end

function sprites.get(name)
    return registry[name]
end

return sprites

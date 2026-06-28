local sprites     = {}
local registry    = {}
local constants   = require("src/constants")
local TILE_SIZE   = constants.TILE_SIZE

local sprite_order = { "wall", "open", "ladder", "spawner", "adventurer", "monster" }

function sprites.load()
    local data = love.image.newImageData("sprites.png")

    data:mapPixel(function(x, y, r, g, b, a)
        -- magenta (255, 0, 255) is the transparency key color
        if r == 1 and g == 0 and b == 1 then
            return 0, 0, 0, 0
        end
        return r, g, b, a
    end)

    local image = love.graphics.newImage(data)

    for i, name in ipairs(sprite_order) do
        local quad = love.graphics.newQuad(
            (i - 1) * TILE_SIZE, 0,
            TILE_SIZE, TILE_SIZE,
            image:getDimensions()
        )
        registry[name] = { image = image, quad = quad }
    end

    registry["floor"] = registry["wall"]
end

function sprites.get(name)
    return registry[name]
end

return sprites

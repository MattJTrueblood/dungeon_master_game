local sprites = {}
local registry = {}

local function makeSprite(r, g, b)
    local canvas = love.graphics.newCanvas(16, 16)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(r, g, b, 1)
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    return canvas
end

function sprites.load()
    registry["floor"]      = makeSprite(0.50, 0.50, 0.50)
    registry["wall"]       = makeSprite(0.25, 0.25, 0.25)
    registry["ladder"]     = makeSprite(0.60, 0.40, 0.20)
    registry["door"]       = makeSprite(0.70, 0.60, 0.40)
    registry["spawner"]    = makeSprite(0.50, 0.10, 0.10)
    registry["adventurer"] = makeSprite(0.20, 0.40, 0.80)
    registry["monster"]    = makeSprite(0.80, 0.20, 0.20)
end

function sprites.get(name)
    return registry[name]
end

return sprites

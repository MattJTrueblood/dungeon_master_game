local sprites     = {}
local registry    = {}
local constants   = require("src/constants")
local TILE_SIZE   = constants.TILE_SIZE

local T = TILE_SIZE
local sprite_defs = {
    { name = "wall",      x = 0*T, y = 0*T, w = T,   h = T   },
    { name = "open",      x = 1*T, y = 0*T, w = T,   h = T   },
    { name = "ladder",    x = 2*T, y = 0*T, w = T,   h = T   },
    { name = "spawner",   x = 3*T, y = 0*T, w = T,   h = T   },
    { name = "adventurer_1", x = 4*T, y = 0*T, w = T, h = T },
    { name = "adventurer_2", x = 0*T, y = 2*T, w = T, h = T },
    { name = "adventurer_3", x = 1*T, y = 2*T, w = T, h = T },
    { name = "monster_easy", x = 5*T, y = 0*T, w = T,   h = T   },
    { name = "monster_medium", x = 6*T, y = 0*T, w = T,   h = T   },
    { name = "monster_hard",  x = 7*T, y = 0*T, w = T,   h = T   },
    { name = "sky",            x = 0*T, y = 1*T, w = T,   h = T   },
    { name = "grass",          x = 1*T, y = 1*T, w = T,   h = T   },
    { name = "house1",         x = 2*T, y = 1*T, w = 2*T, h = 2*T },
    { name = "house2",         x = 4*T, y = 1*T, w = 2*T, h = 2*T },
    { name = "monster_boss",   x = 6*T, y = 1*T, w = 2*T, h = 2*T },
    { name = "boss_spawner",   x = 8*T, y = 1*T, w = 2*T, h = 2*T },
}

function sprites.load()
    local data = love.image.newImageData("sprites.png")

    data:mapPixel(function(x, y, r, g, b, a)
        if r == 1 and g == 0 and b == 1 then return 0, 0, 0, 0 end
        return r, g, b, a
    end)

    local image = love.graphics.newImage(data)

    for _, def in ipairs(sprite_defs) do
        local quad = love.graphics.newQuad(def.x, def.y, def.w, def.h, image:getDimensions())
        registry[def.name] = { image = image, quad = quad }
    end

    registry["floor"]      = registry["wall"]
    registry["adventurer"] = registry["adventurer_1"]
end

function sprites.get(name)
    return registry[name]
end

return sprites

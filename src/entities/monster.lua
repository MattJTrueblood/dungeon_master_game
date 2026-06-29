local monster   = {}
local constants = require("src/constants")
local TILE_SIZE = constants.TILE_SIZE

function monster.new(block)
    local h   = #block.tiles
    local w   = #block.tiles[1]
    local col = math.floor(w / 2)
    return {
        position = {
            x = block.position.x + (col - 1) * TILE_SIZE,
            y = block.position.y + (h - 2)   * TILE_SIZE,
        },
        sprite = "monster",
        health = { current = 40, max = 40 },
        nav = {
            current_block = block,
            route         = {},
            waypoint      = nil,
            speed         = 175,
        },
        ai = {
            state      = "idle",
            idle_timer = 0,
        },
    }
end

return monster

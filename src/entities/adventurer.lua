local adventurer = {}
local constants  = require("src/constants")
local TILE_SIZE  = constants.TILE_SIZE

function adventurer.new(block, col)
    local h   = #block.tiles
    local w   = #block.tiles[1]
    local col = col or math.floor(w / 2)
    return {
        position = {
            x = block.position.x + (col - 1) * TILE_SIZE,
            y = block.position.y + (h - 2)   * TILE_SIZE,
        },
        sprite = "adventurer",
        health = { current = 100, max = 100 },
        nav = {
            current_block = block,
            route         = {},
            waypoint      = nil,
            speed         = 250,
        },
        ai = {
            state      = "idle",
            idle_timer = 0,
        },
    }
end

return adventurer

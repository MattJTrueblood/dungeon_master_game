local monster   = {}
local constants = require("src/constants")
local TILE_SIZE = constants.TILE_SIZE

local STATS = {
    easy   = { sprite = "monster_easy",   health = 40,  speed = 175 },
    medium = { sprite = "monster_medium", health = 80,  speed = 200 },
    hard   = { sprite = "monster_hard",   health = 150, speed = 225 },
}

function monster.new(block, difficulty)
    local stat = STATS[difficulty] or STATS.easy
    local h    = #block.tiles
    local w    = #block.tiles[1]
    local col  = math.floor(w / 2)
    return {
        position = {
            x = block.position.x + (col - 1) * TILE_SIZE,
            y = block.position.y + (h - 2)   * TILE_SIZE,
        },
        sprite     = stat.sprite,
        health     = { current = stat.health, max = stat.health },
        is_monster = true,
        nav = {
            current_block = block,
            floor         = block.floor,
            route         = {},
            waypoint      = nil,
            speed         = stat.speed,
        },
        ai = {
            state      = "idle",
            idle_timer = 0,
        },
    }
end

return monster

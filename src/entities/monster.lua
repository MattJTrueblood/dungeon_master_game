local monster   = {}
local constants = require("src/constants")
local TILE_SIZE = constants.TILE_SIZE

local STATS = {
    easy   = { sprite = "monster_easy",   health = 40,  speed = 175, attack_power = 5  },
    medium = { sprite = "monster_medium", health = 80,  speed = 200, attack_power = 10 },
    hard   = { sprite = "monster_hard",   health = 150, speed = 225, attack_power = 20 },
    boss   = { sprite = "monster_boss",   health = 500, speed = 80,  attack_power = 50 },
}

function monster.new(block, difficulty)
    local stat = STATS[difficulty] or STATS.easy
    local h    = #block.tiles
    local w    = #block.tiles[1]
    local col  = math.floor(w / 2)
    return {
        position = {
            x = block.position.x + (col - 1) * TILE_SIZE,
            y = block.position.y + ((difficulty == "boss") and (h - 3) or (h - 2)) * TILE_SIZE,
        },
        sprite       = stat.sprite,
        health       = { current = stat.health, max = stat.health },
        attack_power = stat.attack_power,
        faction      = "monster",
        is_monster   = true,
        is_boss    = difficulty == "boss" or nil,
        nav = {
            current_block = block,
            floor              = block.floor,
            confined_to_block  = difficulty == "boss" or nil,
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

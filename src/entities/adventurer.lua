local adventurer = {}
local constants  = require("src/constants")
local TILE_SIZE  = constants.TILE_SIZE

local STATS = {
    [1] = { health = 60,  attack_power = 10, speed = 250 },
    [2] = { health = 120, attack_power = 22, speed = 270 },
    [3] = { health = 220, attack_power = 40, speed = 290 },
}

function adventurer.new(block, col, tier)
    local h   = #block.tiles
    local w   = #block.tiles[1]
    local col  = col  or math.floor(w / 2)
    local tier = tier or 1
    local stat = STATS[tier]
    return {
        position = {
            x = block.position.x + (col - 1) * TILE_SIZE,
            y = block.position.y + (h - 2)   * TILE_SIZE,
        },
        tier   = tier,
        sprite = "adventurer_" .. tier,
        health = { current = stat.health, max = stat.health },
        nav = {
            current_block = block,
            route         = {},
            waypoint      = nil,
            speed         = stat.speed,
        },
        ai = {
            state      = "idle",
            idle_timer = 0,
        },
        faction      = "adventurer",
        attack_power = stat.attack_power,
        reveals_fog  = true,
    }
end

return adventurer

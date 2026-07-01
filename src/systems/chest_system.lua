local tiny      = require("tiny")
local constants = require("src/constants")
local TILE_SIZE = constants.TILE_SIZE

local CHEST_GOLD_PER_FLOOR = 25

local system = tiny.processingSystem()
system.filter = tiny.requireAll("position", "nav", "gold", "faction")

local function find_chest_col(block)
    local h         = #block.tiles
    local w         = #block.tiles[1]
    local stand_row = h - 1
    for col = 2, w - 1 do
        if block.tiles[stand_row][col] == "chest" then
            return col, stand_row, h
        end
    end
    return nil
end

function system:process(entity, dt)
    if entity.faction ~= "adventurer" then return end
    if entity.retreating then return end

    local state = entity.ai.state
    if state == "pre_combat" or state == "combat" then return end

    local nav   = entity.nav
    local block = nav.current_block
    if not block or not block.tiles then return end

    -- don't divert while mid-crossing between blocks
    if nav.crossing then
        nav.chest_waypoint = false
        return
    end

    local h         = #block.tiles
    local w         = #block.tiles[1]
    local stand_row = h - 1
    local pos       = entity.position

    -- collect if standing on chest tile (round to nearest col to handle arrival threshold slop)
    local cur_col = math.floor((pos.x - block.position.x + TILE_SIZE / 2) / TILE_SIZE) + 1
    if cur_col >= 1 and cur_col <= w and block.tiles[stand_row][cur_col] == "chest" then
        entity.gold        = entity.gold + CHEST_GOLD_PER_FLOOR * (block.floor or 1)
        block.tiles[stand_row][cur_col] = "open"
        nav.chest_waypoint = false
        return
    end

    -- if already diverting, keep going (don't re-override)
    if nav.chest_waypoint then return end

    -- divert toward chest if one exists in this block
    local chest_col = find_chest_col(block)
    if chest_col then
        nav.waypoint       = {
            x = block.position.x + (chest_col - 1) * TILE_SIZE,
            y = block.position.y + (stand_row - 1) * TILE_SIZE,
        }
        nav.route          = {}
        nav.chest_waypoint = true
        entity.ai.state    = "wander"
    end
end

local chest_system = {}
chest_system.system = system
return chest_system

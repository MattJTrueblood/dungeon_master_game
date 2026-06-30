local town_gen  = {}
local constants = require("src/constants")
local TILE_SIZE = constants.TILE_SIZE

local TOWN_W     = 75
local TOWN_H     = 30
local CENTER_COL = math.ceil(TOWN_W / 2)  -- 38

local function make_town_tiles()
    local tiles = {}
    for row = 1, TOWN_H do
        tiles[row] = {}
        for col = 1, TOWN_W do
            tiles[row][col] = (row == TOWN_H) and "grass" or "sky"
        end
    end
    tiles[TOWN_H][CENTER_COL] = "ladder"
    return tiles
end

function town_gen.generate(dungeon_entrance)
    local town_y = -(TOWN_H * TILE_SIZE)

    local town_block = {
        position    = { x = 0, y = town_y },
        tiles       = make_town_tiles(),
        revealed    = true,
        connections = {},
    }

    local col_in_dungeon = CENTER_COL - dungeon_entrance.position.x / TILE_SIZE
    local dh = #dungeon_entrance.tiles

    for row = 1, dh - 1 do
        dungeon_entrance.tiles[row][col_in_dungeon] = "ladder"
    end

    town_block.connections[1] = {
        from_block = town_block,
        from_tile  = { TOWN_H - 1, CENTER_COL },
        to_block   = dungeon_entrance,
        to_tile    = { dh - 1, col_in_dungeon },
        kind       = "vertical",
    }
    dungeon_entrance.connections[#dungeon_entrance.connections + 1] = {
        from_block = dungeon_entrance,
        from_tile  = { dh - 1, col_in_dungeon },
        to_block   = town_block,
        to_tile    = { TOWN_H - 1, CENTER_COL },
        kind       = "vertical",
    }

    local house_y      = town_y + (TOWN_H - 3) * TILE_SIZE
    local house_sprites = { "house1", "house2" }
    local HOUSE_W      = 2  -- tiles
    local CLUSTER_MIN  = 15
    local CLUSTER_MAX  = TOWN_W - HOUSE_W - 5

    local placed = {}
    local house_entities = {}

    local function overlaps(col)
        -- avoid the ladder and a 1-tile gap either side
        if col + HOUSE_W > CENTER_COL - 1 and col < CENTER_COL + 2 then return true end
        for _, c in ipairs(placed) do
            if col < c + HOUSE_W and col + HOUSE_W > c then return true end
        end
        return false
    end

    for _ = 1, 8 do
        for _ = 1, 20 do
            local col = math.random(CLUSTER_MIN, CLUSTER_MAX)
            if not overlaps(col) then
                placed[#placed + 1] = col
                house_entities[#house_entities + 1] = {
                    position = { x = (col - 1) * TILE_SIZE, y = house_y },
                    sprite   = house_sprites[math.random(#house_sprites)],
                }
                break
            end
        end
    end

    return town_block, house_entities
end

town_gen.town_y = -(TOWN_H * TILE_SIZE)

return town_gen

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

    -- guild hall placed first so houses avoid it
    local GUILD_W = 3
    local gh_col
    for _ = 1, 50 do
        local candidate = math.random(4, TOWN_W - GUILD_W - 3)
        if math.abs(candidate - CENTER_COL) > GUILD_W + 2 then
            gh_col = candidate
            break
        end
    end
    gh_col = gh_col or (CENTER_COL > TOWN_W / 2 and 4 or TOWN_W - GUILD_W - 3)

    local house_y       = town_y + (TOWN_H - 3) * TILE_SIZE
    local house_sprites = { "house1", "house2" }
    local HOUSE_W       = 2
    local CLUSTER_MIN   = 3
    local CLUSTER_MAX   = TOWN_W - HOUSE_W - 2

    local placed = {}
    local house_entities = {}

    local function overlaps(col)
        if col + HOUSE_W > CENTER_COL - 1 and col < CENTER_COL + 2 then return true end
        if col + HOUSE_W > gh_col - 1 and col < gh_col + GUILD_W + 1 then return true end
        for _, c in ipairs(placed) do
            if col < c + HOUSE_W and col + HOUSE_W > c then return true end
        end
        return false
    end

    for _ = 1, 8 do
        for _ = 1, 30 do
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

    local guild_hall = {
        position = { x = (gh_col - 1) * TILE_SIZE, y = town_y + (TOWN_H - 4) * TILE_SIZE },
        sprite   = "guild_hall",
    }

    return town_block, house_entities, guild_hall
end

town_gen.town_y = -(TOWN_H * TILE_SIZE)

return town_gen

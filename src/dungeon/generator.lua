local generator      = {}
local constants      = require("src/constants")
local connectivity   = require("src/dungeon/connectivity")

local TILE_SIZE = constants.TILE_SIZE
local LAYER_W   = 75
local LAYER_H   = 40
local UNIT      = 5
local GRID_W    = LAYER_W / UNIT  -- 15 cells
local GRID_H    = LAYER_H / UNIT  -- 10 cells

local function make_block_tiles(w, h)
    local tiles = {}
    for row = 1, h do
        tiles[row] = {}
        for col = 1, w do
            if col == 1 or col == w then
                tiles[row][col] = "wall"
            elseif row == 1 then
                tiles[row][col] = "wall"
            elseif row == h then
                tiles[row][col] = "floor"
            else
                tiles[row][col] = "open"
            end
        end
    end
    return tiles
end

local function new_grid()
    local grid = {}
    for r = 1, GRID_H do
        grid[r] = {}
        for c = 1, GRID_W do grid[r][c] = false end
    end
    return grid
end

local function can_place(grid, r, c, cell_w, cell_h)
    if r + cell_h - 1 > GRID_H or c + cell_w - 1 > GRID_W then return false end
    for dr = 0, cell_h - 1 do
        for dc = 0, cell_w - 1 do
            if grid[r + dr][c + dc] then return false end
        end
    end
    return true
end

local function mark_grid(grid, r, c, cell_w, cell_h)
    for dr = 0, cell_h - 1 do
        for dc = 0, cell_w - 1 do
            grid[r + dr][c + dc] = true
        end
    end
end

local function add_block(blocks, world_x, world_y, cell_col, cell_row, cell_w, cell_h, floor)
    blocks[#blocks + 1] = {
        position = {
            x = world_x + (cell_col - 1) * UNIT * TILE_SIZE,
            y = world_y + (cell_row - 1) * UNIT * TILE_SIZE,
        },
        tiles    = make_block_tiles(cell_w * UNIT, cell_h * UNIT),
        revealed = false,
        floor    = floor,
    }
end

local function scatter(grid, blocks, world_x, world_y, floor, sizes, attempts)
    for _ = 1, attempts do
        local size   = sizes[math.random(#sizes)]
        local cell_w = size[1]
        local cell_h = size[2]
        local r      = math.random(1, GRID_H)
        local c      = math.random(1, GRID_W)
        if can_place(grid, r, c, cell_w, cell_h) then
            mark_grid(grid, r, c, cell_w, cell_h)
            add_block(blocks, world_x, world_y, c, r, cell_w, cell_h, floor)
        end
    end
end

function generator.generate_layer(world_x, world_y, floor)
    local grid   = new_grid()
    local blocks = {}

    scatter(grid, blocks, world_x, world_y, floor, {{3,3},{3,2}}, 10)
    scatter(grid, blocks, world_x, world_y, floor, {{2,2},{2,1}}, 40)

    for r = 1, GRID_H do
        for c = 1, GRID_W do
            if not grid[r][c] then
                mark_grid(grid, r, c, 1, 1)
                add_block(blocks, world_x, world_y, c, r, 1, 1, floor)
            end
        end
    end

    connectivity.connect(blocks)

    -- find the top-row block covering the center column (always exists)
    local center_x = world_x + (math.ceil(GRID_W / 2) - 1) * UNIT * TILE_SIZE
    local entrance
    for _, block in ipairs(blocks) do
        if block.position.y == world_y
        and block.position.x <= center_x
        and block.position.x + #block.tiles[1] * TILE_SIZE > center_x then
            entrance = block
            break
        end
    end

    -- mark outermost blocks as spawners
    local layer_x2 = world_x + LAYER_W * TILE_SIZE
    local layer_y2 = world_y + LAYER_H * TILE_SIZE
    local outermost = {}
    for _, block in ipairs(blocks) do
        local bx2 = block.position.x + #block.tiles[1] * TILE_SIZE
        local by2 = block.position.y + #block.tiles   * TILE_SIZE
        if block.position.x == world_x or bx2 == layer_x2 then
            outermost[#outermost + 1] = block
        end
    end
    for i = #outermost, 2, -1 do
        local j = math.random(i)
        outermost[i], outermost[j] = outermost[j], outermost[i]
    end
    local placed = 0
    for i = 1, #outermost do
        if placed >= 3 then break end
        local b   = outermost[i]
        local h   = #b.tiles
        local w   = #b.tiles[1]
        local col = (b.position.x == world_x) and 2 or (w - 1)
        if b.tiles[h - 1][col] ~= "ladder" then
            b.tiles[h - 1][col] = "spawner"
            b.has_spawner        = true
            placed               = placed + 1
        end
        b.has_spawner   = true
    end

    return blocks, entrance
end

generator.layer_w_px = LAYER_W * TILE_SIZE
generator.layer_h_px = LAYER_H * TILE_SIZE

return generator

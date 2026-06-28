local generator      = {}
local constants      = require("src/constants")
local connectivity   = require("src/dungeon/connectivity")

local TILE_SIZE = constants.TILE_SIZE
local LAYER_W   = 75
local LAYER_H   = 50
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

local function add_block(blocks, world_x, world_y, cell_col, cell_row, cell_w, cell_h)
    blocks[#blocks + 1] = {
        position = {
            x = world_x + (cell_col - 1) * UNIT * TILE_SIZE,
            y = world_y + (cell_row - 1) * UNIT * TILE_SIZE,
        },
        tiles    = make_block_tiles(cell_w * UNIT, cell_h * UNIT),
        revealed = true,
    }
end

local function scatter(grid, blocks, world_x, world_y, sizes, attempts)
    for _ = 1, attempts do
        local size   = sizes[math.random(#sizes)]
        local cell_w = size[1]
        local cell_h = size[2]
        local r      = math.random(1, GRID_H)
        local c      = math.random(1, GRID_W)
        if can_place(grid, r, c, cell_w, cell_h) then
            mark_grid(grid, r, c, cell_w, cell_h)
            add_block(blocks, world_x, world_y, c, r, cell_w, cell_h)
        end
    end
end

function generator.generate_layer(world_x, world_y)
    math.randomseed(os.time())
    local grid   = new_grid()
    local blocks = {}

    scatter(grid, blocks, world_x, world_y, {{3,3},{3,2}}, 10)
    scatter(grid, blocks, world_x, world_y, {{2,2},{2,1}}, 40)

    for r = 1, GRID_H do
        for c = 1, GRID_W do
            if not grid[r][c] then
                mark_grid(grid, r, c, 1, 1)
                add_block(blocks, world_x, world_y, c, r, 1, 1)
            end
        end
    end

    connectivity.connect(blocks)
    return blocks
end

generator.layer_w_px = LAYER_W * TILE_SIZE
generator.layer_h_px = LAYER_H * TILE_SIZE

return generator

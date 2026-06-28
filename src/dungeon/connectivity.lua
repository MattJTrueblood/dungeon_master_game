local connectivity   = {}
local constants      = require("src/constants")
local TILE_SIZE      = constants.TILE_SIZE
local HALLWAY_BIAS   = 0.75  -- probability of preferring a horizontal edge when one is available

local function tile_x(block)  return block.position.x / TILE_SIZE end
local function tile_y(block)  return block.position.y / TILE_SIZE end
local function tile_w(block)  return #block.tiles[1] end
local function tile_h(block)  return #block.tiles end
local function floor_y(block) return tile_y(block) + tile_h(block) - 1 end

local function is_horizontal_neighbor(a, b)
    return tile_x(a) + tile_w(a) == tile_x(b)
       and floor_y(a) == floor_y(b)
end

local function is_vertical_neighbor(above, below)
    if tile_y(above) + tile_h(above) ~= tile_y(below) then return false end
    return tile_x(above) < tile_x(below) + tile_w(below)
       and tile_x(below) < tile_x(above) + tile_w(above)
end

local function build_edges(blocks)
    local edges = {}
    for i = 1, #blocks do
        for j = i + 1, #blocks do
            local a, b = blocks[i], blocks[j]
            if is_horizontal_neighbor(a, b) then
                edges[#edges + 1] = { a = a, b = b, kind = "horizontal" }
            elseif is_horizontal_neighbor(b, a) then
                edges[#edges + 1] = { a = b, b = a, kind = "horizontal" }
            end
            if is_vertical_neighbor(a, b) then
                edges[#edges + 1] = { a = a, b = b, kind = "vertical" }
            elseif is_vertical_neighbor(b, a) then
                edges[#edges + 1] = { a = b, b = a, kind = "vertical" }
            end
        end
    end
    return edges
end

local function run_prims(blocks, edges)
    local in_tree      = {}
    local tree_edges   = {}
    local tree_edge_set = {}
    in_tree[blocks[1]] = true

    for _ = 1, #blocks - 1 do
        local frontier = {}
        for _, edge in ipairs(edges) do
            local a_in = in_tree[edge.a]
            local b_in = in_tree[edge.b]
            if (a_in and not b_in) or (not a_in and b_in) then
                frontier[#frontier + 1] = edge
            end
        end
        if #frontier == 0 then break end

        local horizontal = {}
        local vertical   = {}
        for _, e in ipairs(frontier) do
            if e.kind == "horizontal" then horizontal[#horizontal+1] = e
            else                           vertical[#vertical+1]     = e end
        end

        local pool
        if #horizontal > 0 and (#vertical == 0 or math.random() < HALLWAY_BIAS) then
            pool = horizontal
        else
            pool = vertical
        end
        local chosen = pool[math.random(#pool)]
        tree_edges[#tree_edges + 1] = chosen
        tree_edge_set[chosen]        = true
        in_tree[chosen.a]            = true
        in_tree[chosen.b]            = true
    end

    return tree_edges, tree_edge_set
end

local function punch_horizontal(left, right)
    local h_left  = tile_h(left)
    local h_right = tile_h(right)
    left.tiles[h_left - 1][tile_w(left)]  = "open"
    left.tiles[h_left][tile_w(left)]       = "floor"
    right.tiles[h_right - 1][1]            = "open"
    right.tiles[h_right][1]                = "floor"
end

local function punch_vertical(above, below)
    local tx_above = tile_x(above)
    local tx_below = tile_x(below)

    -- interior world-tile col range valid for both blocks (avoid edge wall cols)
    local valid_start = math.max(tx_above + 1, tx_below + 1)
    local valid_end   = math.min(tx_above + tile_w(above) - 2, tx_below + tile_w(below) - 2)

    if valid_start > valid_end then return end

    local world_col = math.random(valid_start, valid_end)
    local col_above = world_col - tx_above + 1
    local col_below = world_col - tx_below + 1

    above.tiles[tile_h(above)][col_above] = "ladder"
    for row = 1, tile_h(below) - 1 do
        below.tiles[row][col_below] = "ladder"
    end
end

function connectivity.connect(blocks)
    local all_edges              = build_edges(blocks)
    local tree_edges, tree_set   = run_prims(blocks, all_edges)

    local remaining = {}
    for _, edge in ipairs(all_edges) do
        if not tree_set[edge] then
            remaining[#remaining + 1] = edge
        end
    end

    for i = #remaining, 2, -1 do
        local j = math.random(i)
        remaining[i], remaining[j] = remaining[j], remaining[i]
    end

    local loop_count = math.floor(#remaining * 0.25)
    for i = 1, loop_count do
        tree_edges[#tree_edges + 1] = remaining[i]
    end

    for _, edge in ipairs(tree_edges) do
        if edge.kind == "horizontal" then
            punch_horizontal(edge.a, edge.b)
        else
            punch_vertical(edge.a, edge.b)
        end
    end
end

return connectivity

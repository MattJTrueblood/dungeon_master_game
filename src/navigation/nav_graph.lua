local nav_graph = {}
local constants = require("src/constants")
local TILE_SIZE = constants.TILE_SIZE

function nav_graph.tile_world_pos(block, row, col)
    return {
        x = block.position.x + (col - 1) * TILE_SIZE,
        y = block.position.y + (row - 1) * TILE_SIZE,
    }
end

-- BFS over block connections; returns ordered list of Connections to follow, or nil
function nav_graph.find_route(from_block, to_block)
    if from_block == to_block then return {} end

    local visited = { [from_block] = true }
    local queue   = { { block = from_block, path = {} } }
    local head    = 1

    while head <= #queue do
        local current = queue[head]
        head = head + 1

        for _, conn in ipairs(current.block.connections) do
            local neighbor = conn.to_block
            if not visited[neighbor] then
                visited[neighbor] = true
                local new_path = {}
                for i = 1, #current.path do new_path[i] = current.path[i] end
                new_path[#new_path + 1] = conn

                if neighbor == to_block then
                    return new_path
                end

                queue[#queue + 1] = { block = neighbor, path = new_path }
            end
        end
    end

    return nil
end

return nav_graph

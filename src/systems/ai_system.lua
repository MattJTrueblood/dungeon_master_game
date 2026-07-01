local tiny      = require("tiny")
local nav_graph = require("src/navigation/nav_graph")

local system = tiny.processingSystem()
system.filter             = tiny.requireAll("nav", "ai")
system.all_blocks         = nil  -- shared mutable table set from main.lua
system.floor_restrictions = nil  -- {[tier] = {min, max}} set from main.lua
system.deepest_generated  = 1   -- updated by main.lua as floors are stepped into

function system:process(entity, dt)
    local ai  = entity.ai
    local nav = entity.nav

    if ai.state ~= "idle" then return end
    if entity.retreating then return end

    ai.idle_timer = ai.idle_timer - dt
    if ai.idle_timer > 0 then return end

    if nav.confined_to_block then
        local block   = nav.current_block
        local h       = #block.tiles
        local w       = #block.tiles[1]
        local row     = entity.is_boss and (h - 2) or (h - 1)
        local max_col = entity.is_boss and (w - 2) or (w - 1)
        nav.waypoint  = nav_graph.tile_world_pos(block, row, math.random(2, max_col))
        ai.state      = "wander"
        return
    end

    local all = self.all_blocks or {}

    local candidates
    if entity.tier and self.floor_restrictions then
        local rest = self.floor_restrictions[entity.tier]
        if rest then
            local max_floor = math.min(rest.max or 999, self.deepest_generated)
            candidates = {}
            for _, b in ipairs(all) do
                if b.floor and b.floor >= rest.min and b.floor <= max_floor then
                    candidates[#candidates + 1] = b
                end
            end
        end
    elseif nav.floor then
        candidates = {}
        for _, b in ipairs(all) do
            if b.floor == nav.floor then candidates[#candidates + 1] = b end
        end
    end
    if not candidates or #candidates == 0 then candidates = all end
    if #candidates == 0 then return end

    local unexplored = {}
    for _, b in ipairs(candidates) do
        if not b.revealed then unexplored[#unexplored + 1] = b end
    end
    local pool = #unexplored > 0 and unexplored or candidates

    for _ = 1, 10 do
        local dest = pool[math.random(#pool)]
        if dest ~= nav.current_block then
            local route = nav_graph.find_route(nav.current_block, dest)
            if route == nil then
                print("WARNING: no route found from " .. tostring(nav.current_block) .. " to " .. tostring(dest))
            end
            if route and #route > 0 then
                nav.route    = route
                nav.waypoint = nav_graph.tile_world_pos(nav.current_block, route[1].from_tile[1], route[1].from_tile[2])
                ai.state     = "wander"
                return
            end
        end
    end

    print("WARNING: entity could not find a route from block " .. tostring(nav.current_block) .. " after 10 attempts")
    ai.idle_timer = 0.5
end

local ai_system = {}
ai_system.system = system
return ai_system

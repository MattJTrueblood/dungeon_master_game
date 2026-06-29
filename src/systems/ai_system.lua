local tiny      = require("tiny")
local nav_graph = require("src/navigation/nav_graph")

local system = tiny.processingSystem()
system.filter = tiny.requireAll("nav", "ai")
system.blocks = nil  -- set from main.lua after world creation

function system:process(entity, dt)
    local ai  = entity.ai
    local nav = entity.nav

    if ai.state ~= "idle" then return end

    ai.idle_timer = ai.idle_timer - dt
    if ai.idle_timer > 0 then return end

    local blocks = self.blocks
    if not blocks or #blocks == 0 then return end

    for _ = 1, 10 do
        local dest = blocks[math.random(#blocks)]
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

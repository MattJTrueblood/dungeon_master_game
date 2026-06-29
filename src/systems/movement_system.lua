local tiny      = require("tiny")
local nav_graph = require("src/navigation/nav_graph")
local constants = require("src/constants")

local ARRIVAL_THRESHOLD = constants.TILE_SIZE / 8

local function go_idle(entity)
    entity.nav.waypoint  = nil
    entity.ai.state      = "idle"
    entity.ai.idle_timer = 0
end

local function set_next_waypoint(entity)
    local nav = entity.nav
    if #nav.route > 0 then
        local next_conn = nav.route[1]
        nav.waypoint = nav_graph.tile_world_pos(nav.current_block, next_conn.from_tile[1], next_conn.from_tile[2])
    else
        go_idle(entity)
    end
end

local system = tiny.processingSystem()
system.filter = tiny.requireAll("position", "nav")

function system:process(entity, dt)
    local nav = entity.nav
    if not nav.waypoint then return end

    local pos  = entity.position
    local wp   = nav.waypoint
    local dx   = wp.x - pos.x
    local dy   = wp.y - pos.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist <= ARRIVAL_THRESHOLD then
        if nav.crossing then
            nav.crossing = nil
            table.remove(nav.route, 1)
            set_next_waypoint(entity)

        elseif #nav.route > 0 then
            local conn   = nav.route[1]
            local to_pos = nav_graph.tile_world_pos(conn.to_block, conn.to_tile[1], conn.to_tile[2])
            if conn.kind == "vertical" then
                pos.x = wp.x
            end
            nav.current_block = conn.to_block
            nav.waypoint      = to_pos
            nav.crossing      = conn

        else
            go_idle(entity)
        end
    else
        pos.x = pos.x + (dx / dist) * nav.speed * dt
        pos.y = pos.y + (dy / dist) * nav.speed * dt
    end
end

local movement_system = {}
movement_system.system = system
return movement_system

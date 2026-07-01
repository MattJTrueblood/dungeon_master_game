local tiny      = require("tiny")
local sprites   = require("src/sprites")
local camera    = require("src/camera")
local constants = require("src/constants")

local TILE_SIZE    = constants.TILE_SIZE
local DEBUG_ROUTES = constants.DEBUG_ROUTES
local REVEAL_ALL   = constants.REVEAL_ALL
local nav_graph    = DEBUG_ROUTES and require("src/navigation/nav_graph") or nil

local block_render_system = tiny.system()
block_render_system.filter = tiny.requireAll("position", "tiles")

local entity_render_system = tiny.system()
entity_render_system.filter = tiny.requireAll("position", "sprite")

local world_canvas = nil
local canvas_ox    = 0
local canvas_oy    = 0

local FLOOR_TINTS = {
    { 1.0,  1.0,  1.0  },
    { 0.75, 0.85, 1.0  },
    { 0.85, 0.7,  1.0  },
    { 1.0,  0.65, 0.65 },
    { 0.6,  0.4,  0.9  },
}

local function draw_sprite(sprite, x, y)
    love.graphics.draw(sprite.image, sprite.quad, x, y)
end

local function draw_block(block)
    if not REVEAL_ALL and not block.revealed then return end
    local tint    = FLOOR_TINTS[block.floor] or FLOOR_TINTS[1]
    local overlay = { ladder = true, spawner = true, boss_spawner = true, chest = true }

    love.graphics.setColor(tint[1], tint[2], tint[3], 1)
    for row = 1, #block.tiles do
        for col = 1, #block.tiles[row] do
            local tile_type = block.tiles[row][col]
            local bg        = overlay[tile_type] and "open" or tile_type
            local sprite    = sprites.get(bg)
            if sprite then
                local x = block.position.x + (col - 1) * TILE_SIZE
                local y = block.position.y + (row - 1) * TILE_SIZE
                draw_sprite(sprite, x, y)
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    for row = 1, #block.tiles do
        for col = 1, #block.tiles[row] do
            local tile_type = block.tiles[row][col]
            if overlay[tile_type] then
                local sprite = sprites.get(tile_type)
                if sprite then
                    local x = block.position.x + (col - 1) * TILE_SIZE
                    local y = block.position.y + (row - 1) * TILE_SIZE
                    draw_sprite(sprite, x, y)
                end
            end
        end
    end
end

-- LINE DRAWING FOR ROUTE DEBUGGING --

local ROUTE_COLORS = {
    { 1, 1, 0 }, { 0, 1, 1 }, { 1, 0, 1 }, { 1, 0.5, 0 },
    { 0, 1, 0 }, { 0, 0.5, 1 }, { 1, 0, 0.5 }, { 0.5, 1, 0 },
}
local entity_colors = {}
local color_index   = 0

local function get_entity_color(entity)
    if not entity_colors[entity] then
        color_index = (color_index % #ROUTE_COLORS) + 1
        entity_colors[entity] = ROUTE_COLORS[color_index]
    end
    return entity_colors[entity]
end

local function draw_route(entity)
    local nav = entity.nav
    if not nav or not nav.waypoint then return end

    local half = TILE_SIZE / 2
    local points = { entity.position.x + half, entity.position.y + half }

    if nav.crossing then
        points[#points + 1] = nav.waypoint.x + half
        points[#points + 1] = nav.waypoint.y + half
    end

    local start = nav.crossing and 2 or 1
    for i = start, #nav.route do
        local conn = nav.route[i]
        local p = nav_graph.tile_world_pos(conn.from_block, conn.from_tile[1], conn.from_tile[2])
        points[#points + 1] = p.x + half
        points[#points + 1] = p.y + half
        local q = nav_graph.tile_world_pos(conn.to_block, conn.to_tile[1], conn.to_tile[2])
        points[#points + 1] = q.x + half
        points[#points + 1] = q.y + half
    end

    if #points >= 4 then
        local c = get_entity_color(entity)
        love.graphics.setColor(c[1], c[2], c[3], 0.7)
        love.graphics.line(points)
    end
end

local function draw_entity(entity)
    love.graphics.setColor(1, 1, 1, 1)
    local sprite = sprites.get(entity.sprite)
    if sprite then
        local draw_x = entity.position.x + (entity.combat_bump or 0)
        draw_sprite(sprite, draw_x, entity.position.y)
    end
    if entity.health then
        local x   = entity.position.x
        local y   = entity.position.y - 5
        local pct = entity.health.current / entity.health.max
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", x, y, TILE_SIZE, 3)
        love.graphics.setColor(0.1, 0.8, 0.1, 1)
        love.graphics.rectangle("fill", x, y, TILE_SIZE * pct, 3)
    end
end

local render_system = {}
render_system.block_render_system  = block_render_system
render_system.entity_render_system = entity_render_system

function render_system.init(bounds)
    local B  = 3 * TILE_SIZE
    local bw = math.ceil(bounds.x2 - bounds.x1) + 2 * B
    local bh = math.ceil(bounds.y2 - bounds.y1) + 2 * B
    world_canvas = love.graphics.newCanvas(bw, bh)
    canvas_ox = B - bounds.x1
    canvas_oy = B - bounds.y1
end

function render_system.draw()
    if not world_canvas then return end

    love.graphics.setCanvas(world_canvas)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.push()
    love.graphics.translate(canvas_ox, canvas_oy)
    for _, block in ipairs(block_render_system.entities) do
        draw_block(block)
    end
    for _, entity in ipairs(entity_render_system.entities) do
        draw_entity(entity)
        if DEBUG_ROUTES then draw_route(entity) end
    end
    if not REVEAL_ALL then
        love.graphics.setColor(0, 0, 0, 1)
        for _, block in ipairs(block_render_system.entities) do
            if not block.revealed then
                local w = #block.tiles[1] * TILE_SIZE
                local h = #block.tiles    * TILE_SIZE
                love.graphics.rectangle("fill", block.position.x, block.position.y, w, h)
            end
        end
    end
    love.graphics.pop()
    love.graphics.setCanvas()

    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)
    local z  = camera.zoom
    love.graphics.draw(world_canvas, -(camera.x + canvas_ox) * z, -(camera.y + canvas_oy) * z, 0, z, z)
end

return render_system

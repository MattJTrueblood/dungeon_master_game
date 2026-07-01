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

local tint_cache = {}

local function floor_tint(floor)
    if tint_cache[floor] then return tint_cache[floor] end
    -- rotate hue by golden angle per floor, keep saturation and value fixed
    local h = ((floor - 1) * 137.508) % 360  -- golden angle in degrees
    local s = 0.35
    local v = 0.95
    -- HSV to RGB
    local c  = v * s
    local x  = c * (1 - math.abs((h / 60) % 2 - 1))
    local m  = v - c
    local r, g, b
    if     h < 60  then r,g,b = c,x,0
    elseif h < 120 then r,g,b = x,c,0
    elseif h < 180 then r,g,b = 0,c,x
    elseif h < 240 then r,g,b = 0,x,c
    elseif h < 300 then r,g,b = x,0,c
    else                r,g,b = c,0,x
    end
    local t = { r + m, g + m, b + m }
    tint_cache[floor] = t
    return t
end

local function draw_sprite(sprite, x, y)
    love.graphics.draw(sprite.image, sprite.quad, x, y)
end

local function draw_block(block)
    if not REVEAL_ALL and not block.revealed then return end
    local tint    = block.floor and floor_tint(block.floor) or { 1, 1, 1 }
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
    world_canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
    canvas_ox = -bounds.x1
    canvas_oy = -bounds.y1
end

function render_system.draw()
    if not world_canvas then return end

    local z = camera.zoom

    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local view_x1 = camera.x
    local view_y1 = camera.y
    local view_x2 = camera.x + sw / z
    local view_y2 = camera.y + sh / z

    local function block_visible(block)
        local bw = #block.tiles[1] * TILE_SIZE
        local bh = #block.tiles    * TILE_SIZE
        local bx = block.position.x
        local by = block.position.y
        return bx < view_x2 and bx + bw > view_x1
           and by < view_y2 and by + bh > view_y1
    end

    local function entity_visible(entity)
        local x = entity.position.x
        local y = entity.position.y
        return x < view_x2 and x + TILE_SIZE * 2 > view_x1
           and y < view_y2 and y + TILE_SIZE * 2 > view_y1
    end

    love.graphics.setCanvas(world_canvas)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.push()
    love.graphics.scale(z, z)
    love.graphics.translate(-camera.x, -camera.y)
    for _, block in ipairs(block_render_system.entities) do
        if block_visible(block) then draw_block(block) end
    end
    for _, entity in ipairs(entity_render_system.entities) do
        if entity_visible(entity) then
            draw_entity(entity)
            if DEBUG_ROUTES then draw_route(entity) end
        end
    end
    if not REVEAL_ALL then
        love.graphics.setColor(0, 0, 0, 1)
        for _, block in ipairs(block_render_system.entities) do
            if block_visible(block) and not block.revealed then
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
    love.graphics.draw(world_canvas, 0, 0)
end

return render_system

local tiny      = require("tiny")
local sprites   = require("src/sprites")
local camera    = require("src/camera")
local constants = require("src/constants")

local TILE_SIZE = constants.TILE_SIZE

local block_render_system = tiny.system()
block_render_system.filter = tiny.requireAll("position", "tiles")

local entity_render_system = tiny.system()
entity_render_system.filter = tiny.requireAll("position", "sprite")

local function draw_sprite(sprite, x, y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sprite.image, sprite.quad, x, y)
end

local function draw_block(block)
    if not block.revealed then return end
    for row = 1, #block.tiles do
        for col = 1, #block.tiles[row] do
            local tile_type = block.tiles[row][col]
            local sprite    = sprites.get(tile_type)
            if sprite then
                local x = block.position.x + (col - 1) * TILE_SIZE
                local y = block.position.y + (row - 1) * TILE_SIZE
                draw_sprite(sprite, x, y)
            end
        end
    end
end

local function draw_entity(entity)
    local sprite = sprites.get(entity.sprite)
    if sprite then
        draw_sprite(sprite, entity.position.x, entity.position.y)
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

function render_system.draw()
    love.graphics.clear(0, 0, 0, 1)
    camera:apply()
    for _, block in ipairs(block_render_system.entities) do
        draw_block(block)
    end
    for _, entity in ipairs(entity_render_system.entities) do
        draw_entity(entity)
    end
    camera:reset()
    love.graphics.setColor(1, 1, 1, 1)
end

return render_system

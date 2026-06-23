local tiny    = require("tiny")
local sprites = require("src/sprites")
local camera  = require("src/camera")

local TILE_SIZE = 16

local blockRenderSystem = tiny.system()
blockRenderSystem.filter = tiny.requireAll("position", "tiles")

local entityRenderSystem = tiny.system()
entityRenderSystem.filter = tiny.requireAll("position", "sprite")

local function drawSprite(sprite, x, y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sprite.image, sprite.quad, x, y)
end

local function drawBlock(block)
    if not block.revealed then return end
    for row = 1, #block.tiles do
        for col = 1, #block.tiles[row] do
            local tileType = block.tiles[row][col]
            local sprite = sprites.get(tileType)
            if sprite then
                local x = block.position.x + (col - 1) * TILE_SIZE
                local y = block.position.y + (row - 1) * TILE_SIZE
                drawSprite(sprite, x, y)
            end
        end
    end
end

local function drawEntity(entity)
    local sprite = sprites.get(entity.sprite)
    if sprite then
        drawSprite(sprite, entity.position.x, entity.position.y)
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

local renderSystem = {}
renderSystem.blockRenderSystem  = blockRenderSystem
renderSystem.entityRenderSystem = entityRenderSystem

function renderSystem.draw()
    love.graphics.clear(0, 0, 0, 1)
    camera:apply()
    for _, block in ipairs(blockRenderSystem.entities) do
        drawBlock(block)
    end
    for _, entity in ipairs(entityRenderSystem.entities) do
        drawEntity(entity)
    end
    camera:reset()
    love.graphics.setColor(1, 1, 1, 1)
end

return renderSystem

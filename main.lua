if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local tiny            = require("tiny")
local version         = require("version")
local sprites         = require("src/sprites")
local render_system   = require("src/systems/render_system")
local movement_system = require("src/systems/movement_system")
local ai_system       = require("src/systems/ai_system")
local camera          = require("src/camera")
local generator       = require("src/dungeon/generator")
local town_gen        = require("src/town/generator")
local adventurer      = require("src/entities/adventurer")
local monster         = require("src/entities/monster")

local world

function love.load()
    print("loading...")
    love.graphics.setDefaultFilter("nearest", "nearest")
    sprites.load()

    world = tiny.world(
        render_system.block_render_system,
        render_system.entity_render_system,
        movement_system.system,
        ai_system.system
    )

    local blocks, entrance = generator.generate_layer(0, 0)
    local town_block, house_entities = town_gen.generate(entrance)

    world:addEntity(town_block)
    for _, block in ipairs(blocks) do
        world:addEntity(block)
    end
    for _, house in ipairs(house_entities) do
        world:addEntity(house)
    end

    ai_system.system.blocks = blocks

    local town_w = #town_block.tiles[1]
    for _ = 1, 3 do
        local col = math.random(2, town_w - 1)
        world:addEntity(adventurer.new(town_block, col))
    end
    for _ = 1, 5 do
        world:addEntity(monster.new(blocks[math.random(#blocks)]))
    end

    camera.bounds = {
        x1 = 0,
        y1 = town_gen.town_y,
        x2 = generator.layer_w_px,
        y2 = generator.layer_h_px,
    }

    camera.x = 0
    camera.y = town_gen.town_y
    camera:clamp()

    render_system.init(camera.bounds)

    print("loading complete!")
end

function love.mousepressed(x, y, button)
    if button == 1 then camera:start_drag() end
end

function love.mousereleased(x, y, button)
    if button == 1 then camera:end_drag() end
end

function love.wheelmoved(x, y)
    local mx, my = love.mouse.getPosition()
    camera:scroll(y, mx, my)
end

function love.mousemoved(x, y, dx, dy)
    if camera.dragging then
        camera:move_drag(dx, dy)
    end
end

function love.update(dt)
    camera:update(dt)
    world:update(dt)
end

function love.draw()
    render_system.draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("v" .. version.major .. "." .. version.minor .. "." .. version.patch, 10, 10)
end

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

    local screen_w = love.graphics.getDimensions()
    camera.x = (generator.layer_w_px - screen_w) / 2
    camera.y = town_gen.town_y

    print("loading complete!")
end

local CAMERA_SPEED = 200

function love.update(dt)
    if love.keyboard.isDown("left")  then camera.x = camera.x - CAMERA_SPEED * dt end
    if love.keyboard.isDown("right") then camera.x = camera.x + CAMERA_SPEED * dt end
    if love.keyboard.isDown("up")    then camera.y = camera.y - CAMERA_SPEED * dt end
    if love.keyboard.isDown("down")  then camera.y = camera.y + CAMERA_SPEED * dt end
    world:update(dt)
end

function love.draw()
    render_system.draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("v" .. version.major .. "." .. version.minor .. "." .. version.patch, 10, 10)
end

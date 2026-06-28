if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local tiny         = require("tiny")
local version      = require("version")
local sprites      = require("src/sprites")
local render_system = require("src/systems/render_system")
local camera       = require("src/camera")
local generator    = require("src/dungeon/generator")

local world

function love.load()
    sprites.load()

    world = tiny.world(render_system.block_render_system, render_system.entity_render_system)

    local blocks = generator.generate_layer(0, 0)
    for _, block in ipairs(blocks) do
        world:addEntity(block)
    end

    local screen_w, screen_h = love.graphics.getDimensions()
    camera.x = (generator.layer_w_px - screen_w) / 2
    camera.y = 0
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

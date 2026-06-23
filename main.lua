if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local tiny         = require("tiny")
local version      = require("version")
local sprites      = require("src/sprites")
local renderSystem = require("src/systems/render_system")
local camera       = require("src/camera")

local world

function love.load()
    sprites.load()

    world = tiny.world(renderSystem.blockRenderSystem, renderSystem.entityRenderSystem)

    world:addEntity({
        position = { x = 200, y = 200 },
        tiles = {
            { "floor", "floor", "floor", "floor" },
            { "floor", "floor", "floor", "floor" },
            { "floor", "floor", "floor", "floor" },
            { "wall",  "wall",  "wall",  "wall"  },
        },
        revealed = true
    })

    world:addEntity({
        position = { x = 264, y = 200 },
        tiles = {
            { "wall",    "floor",  "floor", "wall"    },
            { "floor",   "floor",  "ladder","floor"   },
            { "floor",   "door",   "floor", "floor"   },
            { "spawner", "floor",  "floor", "spawner" },
        },
        revealed = true
    })

    world:addEntity({
        position = { x = 328, y = 200 },
        tiles = {
            { "floor", "floor", "floor", "floor" },
            { "floor", "floor", "floor", "floor" },
            { "floor", "floor", "floor", "floor" },
            { "floor", "floor", "floor", "floor" },
        },
        revealed = false
    })

    world:addEntity({
        position = { x = 216, y = 216 },
        sprite = "adventurer",
        health = { current = 75, max = 100 }
    })

    world:addEntity({
        position = { x = 280, y = 216 },
        sprite = "monster",
        health = { current = 40, max = 60 }
    })
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
    renderSystem.draw()
    love.graphics.setColor(1, 1, 1, 1)
end

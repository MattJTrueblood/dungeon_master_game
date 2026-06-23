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
            { "wall",  "wall",  "wall",  "wall", "wall"  },
            { "wall",  "open",  "open",  "open", "wall"  },
            { "wall",  "open",  "open",  "open", "wall"  },
            { "wall",  "open",  "open",  "open", "open"  },
            { "wall", "wall", "wall", "wall", "wall" },
        },
        revealed = true
    })

    world:addEntity({
        position = { x = 280, y = 200 },
        tiles = {
            { "wall",  "wall",  "ladder",  "wall", "wall"  },
            { "wall",  "open",  "ladder",  "open", "wall"  },
            { "wall",  "open",  "ladder",  "open", "wall"  },
            { "open",  "open",  "ladder",  "open", "wall"  },
            { "wall", "wall", "ladder", "wall", "wall" },
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
        position = { x = 232, y = 248 },
        sprite = "adventurer",
        health = { current = 75, max = 100 }
    })

    world:addEntity({
        position = { x = 280, y = 248 },
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
end

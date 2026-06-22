require("lldebugger").start()

local tiny = require("tiny")

local world = tiny.world()

function love.draw()
    love.graphics.print("Hello World! tiny-ecs loaded: " .. tostring(world ~= nil), 400, 300)
end

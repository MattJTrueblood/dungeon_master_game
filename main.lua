if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local tiny = require("tiny")
local version = require("version")

local world = tiny.world()

function love.draw()
    love.graphics.print("Dungeon Master v" .. version.major .. "." .. version.minor .. "." .. version.patch, 10, 10)
end

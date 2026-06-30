local version = require("version")

function love.conf(t)
    t.title = "Dungeon Master v" .. version.major .. "." .. version.minor .. "." .. version.patch
    t.version = "11.5"
    t.window.width = 1200
    t.window.height = 720
end

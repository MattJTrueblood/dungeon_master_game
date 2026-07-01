local tiny    = require("tiny")
local monster = require("src/entities/monster")

local SPAWN_INTERVAL = { 10, 8, 6, 5 }
local MAX_POP        = { 3, 4, 5, 5 }
local DIFFICULTIES   = {
    { "easy" },
    { "easy", "medium" },
    { "medium", "hard" },
    { "hard" },
}

local monster_system = tiny.system()
monster_system.filter = tiny.requireAll("is_monster")

local spawner_system = tiny.system()
spawner_system.filter = tiny.requireAll("has_spawner", "floor")

function spawner_system:onAdd(block)
    block.spawn_timer = SPAWN_INTERVAL[block.floor] * math.random()
end

function spawner_system:update(dt)
    local counts = {}
    for _, e in ipairs(monster_system.entities) do
        local f = e.nav and e.nav.floor
        if f then counts[f] = (counts[f] or 0) + 1 end
    end

    for _, block in ipairs(self.entities) do
        local f   = block.floor
        local pop = counts[f] or 0
        if pop < (MAX_POP[f] or 3) then
            block.spawn_timer = block.spawn_timer - dt
            if block.spawn_timer <= 0 then
                local diffs = DIFFICULTIES[f] or { "easy" }
                local diff  = diffs[math.random(#diffs)]
                self.world:addEntity(monster.new(block, diff))
                counts[f]         = pop + 1
                block.spawn_timer = SPAWN_INTERVAL[f] or 10
            end
        end
    end
end

return {
    monster_system = monster_system,
    spawner_system = spawner_system,
}

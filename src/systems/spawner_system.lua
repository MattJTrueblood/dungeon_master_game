local tiny    = require("tiny")
local monster = require("src/entities/monster")

local SPAWN_INTERVAL = { 10, 10, 10, 10, 10 }
local MAX_POP        = { 20, 15, 10, 10, 10 }
local DIFFICULTIES   = {
    { "easy" },
    { "easy", "medium" },
    { "medium"},
    { "medium", "hard" },
    { "hard"}
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
                self.world:addEntity(monster.new(block, diff, block.spawner_col))
                counts[f]         = pop + 1
                block.spawn_timer = SPAWN_INTERVAL[f] or 10
            end
        end
    end
end

local BOSS_SPAWN_INTERVAL = 30

local boss_spawner_system = tiny.system()
boss_spawner_system.filter = tiny.requireAll("has_boss_spawner", "floor")

function boss_spawner_system:onAdd(block)
    block.boss_spawn_timer = BOSS_SPAWN_INTERVAL
end

function boss_spawner_system:update(dt)
    local boss_count = 0
    for _, e in ipairs(monster_system.entities) do
        if e.is_boss then boss_count = boss_count + 1 end
    end

    for _, block in ipairs(self.entities) do
        if boss_count == 0 then
            block.boss_spawn_timer = block.boss_spawn_timer - dt
            if block.boss_spawn_timer <= 0 then
                self.world:addEntity(monster.new(block, "boss", block.boss_spawner_col))
                boss_count             = boss_count + 1
                block.boss_spawn_timer = BOSS_SPAWN_INTERVAL
            end
        end
    end
end

return {
    monster_system     = monster_system,
    spawner_system     = spawner_system,
    boss_spawner_system = boss_spawner_system,
}

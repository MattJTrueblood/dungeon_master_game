local tiny    = require("tiny")
local monster = require("src/entities/monster")

local function get_difficulties(floor)
    if floor <= 1 then return { "easy" }
    elseif floor <= 2 then return { "easy", "medium" }
    elseif floor <= 3 then return { "medium" }
    elseif floor <= 4 then return { "medium", "hard" }
    elseif floor <= 6 then return { "hard" }
    else                    return { "hard", "hard" }
    end
end

local function get_max_pop(floor)
    if floor <= 5 then
        return 22 - floor * 2  -- 20, 18, 16, 14, 12
    else
        return math.min(60, 10 + math.floor((floor - 5) * 2))
    end
end

local function get_spawn_interval(floor)
    return math.max(4, 12 - floor * 0.5)
end

local monster_system = tiny.system()
monster_system.filter = tiny.requireAll("is_monster")

local spawner_system = tiny.system()
spawner_system.filter = tiny.requireAll("has_spawner", "floor")

function spawner_system:onAdd(block)
    block.spawn_timer = get_spawn_interval(block.floor) * math.random()
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
        if pop < get_max_pop(f) then
            block.spawn_timer = block.spawn_timer - dt
            if block.spawn_timer <= 0 then
                local diffs = get_difficulties(f)
                local diff  = diffs[math.random(#diffs)]
                self.world:addEntity(monster.new(block, diff, block.spawner_col))
                counts[f]         = pop + 1
                block.spawn_timer = get_spawn_interval(f)
            end
        end
    end
end

local BOSS_SPAWN_INTERVAL = 45

local boss_spawner_system = tiny.system()
boss_spawner_system.filter = tiny.requireAll("has_boss_spawner", "floor")

function boss_spawner_system:onAdd(block)
    block.boss_spawn_timer   = BOSS_SPAWN_INTERVAL
    block.boss_active_count  = 0  -- bosses this spawner has alive right now
    -- cap grows with depth: 1 at floor 10, +1 every 3 floors, max 6
    block.boss_cap = math.min(6, math.max(1, math.ceil((block.floor - 9) / 3)))
end

function boss_spawner_system:update(dt)
    -- count live bosses per spawner block
    local counts = {}
    for _, e in ipairs(monster_system.entities) do
        if e.is_boss and e.boss_spawner_block then
            local b = e.boss_spawner_block
            counts[b] = (counts[b] or 0) + 1
        end
    end

    for _, block in ipairs(self.entities) do
        local alive = counts[block] or 0
        if alive < block.boss_cap then
            block.boss_spawn_timer = block.boss_spawn_timer - dt
            if block.boss_spawn_timer <= 0 then
                local boss = monster.new(block, "boss", block.boss_spawner_col)
                boss.boss_spawner_block = block  -- back-reference for counting
                self.world:addEntity(boss)
                block.boss_spawn_timer = BOSS_SPAWN_INTERVAL
            end
        end
    end
end

return {
    monster_system      = monster_system,
    spawner_system      = spawner_system,
    boss_spawner_system = boss_spawner_system,
}

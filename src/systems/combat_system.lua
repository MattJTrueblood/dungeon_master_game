local tiny      = require("tiny")
local constants = require("src/constants")
local TILE_SIZE = constants.TILE_SIZE

local COLLISION_DIST   = 4  -- px gap between bounding boxes
local ATTACK_INTERVAL  = 1.2
local BUMP_DIST        = TILE_SIZE * 0.35
local BUMP_DURATION    = 0.25
local PRECOMBAT_SPEED  = 220
local ARRIVAL_EPS      = 2.0

-- find two adjacent valid floor-level tiles in block near mid_x
local function find_combat_positions(block, mid_x)
    local h         = #block.tiles
    local w         = #block.tiles[1]
    local floor_y   = block.position.y + (h - 2) * TILE_SIZE
    local stand_row = h - 1

    local mid_col = math.floor((mid_x - block.position.x) / TILE_SIZE) + 1
    mid_col = math.max(2, math.min(w - 2, mid_col))

    for radius = 0, w do
        for _, start_col in ipairs({ mid_col - radius, mid_col + radius - 1 }) do
            local c1, c2 = start_col, start_col + 1
            if c1 >= 2 and c2 <= w - 1 then
                local t1 = block.tiles[stand_row][c1]
                local t2 = block.tiles[stand_row][c2]
                if t1 ~= "wall" and t1 ~= "ladder"
                and t2 ~= "wall" and t2 ~= "ladder" then
                    local x1 = block.position.x + (c1 - 1) * TILE_SIZE
                    local x2 = block.position.x + (c2 - 1) * TILE_SIZE
                    return { x = x1, y = floor_y }, { x = x2, y = floor_y }
                end
            end
        end
    end
    return nil, nil
end

local function entity_size(e)
    return e.is_boss and 2 * TILE_SIZE or TILE_SIZE
end

local function box_dist(a, b)
    local aw = entity_size(a)
    local bw = entity_size(b)
    local dx = math.max(0, math.max(a.position.x, b.position.x) - math.min(a.position.x + aw, b.position.x + bw))
    local dy = math.max(0, math.max(a.position.y, b.position.y) - math.min(a.position.y + aw, b.position.y + bw))
    return math.sqrt(dx * dx + dy * dy)
end

local function entity_on_ladder(e)
    return e.nav and e.nav.crossing and e.nav.crossing.kind == "vertical"
end

local function clear_nav(e)
    e.nav.waypoint = nil
    e.nav.route    = {}
    e.nav.crossing = nil
end

-- for a boss fight: place the non-boss adjacent to the boss's bounding box
local function find_boss_adjacent(boss, other)
    local block   = boss.nav.current_block
    local h       = #block.tiles
    local w       = #block.tiles[1]
    local floor_y = block.position.y + (h - 2) * TILE_SIZE
    local stand_row = h - 1

    -- which side is the non-boss on?
    local boss_left  = boss.position.x
    local boss_right = boss.position.x + 2 * TILE_SIZE

    local sides = other.position.x < boss_left
        and { boss_left - TILE_SIZE, boss_right }
        or  { boss_right,            boss_left - TILE_SIZE }

    for _, adj_x in ipairs(sides) do
        local col = math.floor((adj_x - block.position.x) / TILE_SIZE) + 1
        if col >= 2 and col <= w - 1 then
            local t = block.tiles[stand_row][col]
            if t ~= "wall" and t ~= "ladder" then
                return { x = adj_x, y = floor_y }
            end
        end
    end
    return nil
end

local function initiate_combat(a, b)
    local mid_x = (a.position.x + b.position.x) / 2
    local pa, pb

    if a.is_boss or b.is_boss then
        local boss  = a.is_boss and a or b
        local other = a.is_boss and b or a
        local adj   = find_boss_adjacent(boss, other)
        if not adj then return end
        pa = a.is_boss and { x = a.position.x, y = a.position.y } or adj
        pb = b.is_boss and { x = b.position.x, y = b.position.y } or adj
    else
        local block = a.nav.current_block
        pa, pb = find_combat_positions(block, mid_x)
        if not pa then
            pa, pb = find_combat_positions(b.nav.current_block, mid_x)
        end
        if not pa then return end
        if a.position.x > b.position.x then pa, pb = pb, pa end
    end

    -- bump_dir: toward opponent, based on final combat positions (not spawn positions)
    local a_center = pa.x + (a.is_boss and TILE_SIZE or TILE_SIZE / 2)
    local b_center = pb.x + (b.is_boss and TILE_SIZE or TILE_SIZE / 2)
    local a_dir = a_center < b_center and 1 or -1
    local b_dir = -a_dir

    clear_nav(a)
    clear_nav(b)

    -- stagger timers by half an interval so they alternate turns
    a.combat = {
        target       = b,
        target_pos   = pa,
        arrived      = a.is_boss or false,
        attack_timer = ATTACK_INTERVAL,
        bump_timer   = 0,
        bump_dir     = a_dir,
        combat_bump  = 0,
    }
    b.combat = {
        target       = a,
        target_pos   = pb,
        arrived      = b.is_boss or false,
        attack_timer = ATTACK_INTERVAL + ATTACK_INTERVAL / 2,
        bump_timer   = 0,
        bump_dir     = b_dir,
        combat_bump  = 0,
    }
    a.ai.state = "pre_combat"
    b.ai.state = "pre_combat"
end

local function move_toward(pos, target, speed, dt)
    local dx   = target.x - pos.x
    local dy   = target.y - pos.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= ARRIVAL_EPS then
        pos.x = target.x
        pos.y = target.y
        return true
    end
    pos.x = pos.x + (dx / dist) * speed * dt
    pos.y = pos.y + (dy / dist) * speed * dt
    return false
end

local system = tiny.system()
system.filter = tiny.requireAll("position", "health", "nav", "ai", "faction")
system.entity_set = {}
function system:onAdd(e)    self.entity_set[e] = true  end
function system:onRemove(e) self.entity_set[e] = nil   end

function system:update(dt)
    local entities = self.entities
    local to_remove = {}

    -- detect new combats
    for i = 1, #entities do
        local a = entities[i]
        local a_state = a.ai.state
        if a_state == "idle" or a_state == "wander" then
            for j = i + 1, #entities do
                local b = entities[j]
                local b_state = b.ai.state
                if b_state == "idle" or b_state == "wander" then
                    if a.faction ~= b.faction then
                        if box_dist(a, b) < COLLISION_DIST then
                            if not entity_on_ladder(a) and not entity_on_ladder(b) then
                                initiate_combat(a, b)
                            end
                        end
                    end
                end
            end
        end
    end

    -- update pre_combat and combat states
    for _, e in ipairs(entities) do
        if to_remove[e] then goto continue end

        local state = e.ai.state

        if (state == "pre_combat" or state == "combat") and e.combat then
            local c      = e.combat
            local target = c.target

            -- orphan check: target removed, queued this frame, or dead but not yet flushed
            if not self.entity_set[target] or to_remove[target]
            or (target.health and target.health.current <= 0) then
                e.combat        = nil
                e.combat_bump   = nil
                e.ai.state      = "idle"
                e.ai.idle_timer = 0
                goto continue
            end

            if state == "pre_combat" then
                local arrived = move_toward(e.position, c.target_pos, PRECOMBAT_SPEED, dt)
                if arrived then
                    c.arrived = true
                    -- transition to combat when both arrive
                    if target.combat and target.combat.arrived and not to_remove[target] then
                        e.ai.state          = "combat"
                        target.ai.state     = "combat"
                        c.attack_timer              = 0.2
                        target.combat.attack_timer  = 0.2 + ATTACK_INTERVAL / 2
                    end
                end

            elseif state == "combat" then
                -- attack timer
                c.attack_timer = c.attack_timer - dt
                if c.attack_timer <= 0 and not c.kill_pending then
                    c.attack_timer = ATTACK_INTERVAL
                    target.health.current = target.health.current - e.attack_power
                    -- trigger bump on this attacker
                    c.bump_timer = BUMP_DURATION
                    -- check target death: let the bump finish before cleaning up
                    if target.health.current <= 0 then
                        to_remove[target] = true
                        c.kill_pending = true
                        if target.kill_gold and e.gold then
                            e.gold = e.gold + target.kill_gold
                            e.xp   = e.xp   + target.kill_xp
                        end
                    end
                end

                -- bump animation
                if c.bump_timer and c.bump_timer > 0 then
                    c.bump_timer = c.bump_timer - dt
                    local t = 1 - (c.bump_timer / BUMP_DURATION)
                    e.combat_bump = math.sin(t * math.pi) * BUMP_DIST * c.bump_dir
                else
                    e.combat_bump = 0
                    if c.kill_pending then
                        e.combat        = nil
                        e.combat_bump   = nil
                        e.ai.state      = "idle"
                        e.ai.idle_timer = 0
                    end
                end
            end
        end

        ::continue::
    end

    for entity in pairs(to_remove) do
        self.world:removeEntity(entity)
    end
end

local combat_system = {}
combat_system.system = system
return combat_system

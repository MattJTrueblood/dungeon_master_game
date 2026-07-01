local tiny      = require("tiny")
local nav_graph = require("src/navigation/nav_graph")
local constants = require("src/constants")
local TILE_SIZE = constants.TILE_SIZE

local GOLD_RETREAT_THRESHOLD = 20
local HEALTH_RETREAT_PCT     = 0.25
local DROPOFF_THRESHOLD      = TILE_SIZE

local system = tiny.processingSystem()
system.filter       = tiny.requireAll("position", "nav", "ai", "health", "gold", "xp", "tier", "faction")
system.town_block   = nil
system.guild_gold   = nil
system.guild_hall_x = nil  -- x position to walk to for dropoff

local adventurer_stats = nil

local function rank_up(entity)
    local new_tier = entity.tier + 1
    local stat     = adventurer_stats[new_tier]
    if not stat then return end

    local pct             = entity.health.current / entity.health.max
    entity.tier           = new_tier
    entity.sprite         = "adventurer_" .. new_tier
    entity.attack_power   = stat.attack_power
    entity.nav.speed      = stat.speed
    entity.health.max     = stat.health
    entity.health.current = math.max(1, math.floor(stat.health * pct))
    entity.xp             = 0
end

local function start_retreat(entity)
    local town = system.town_block
    if not town then return end

    entity.retreating     = true
    entity.ai.state       = "idle"
    entity.ai.idle_timer  = 0
    entity.nav.crossing   = nil  -- cancel in-progress crossing so it doesn't eat retreat route[1]

    if entity.nav.current_block == town then return end

    local route = nav_graph.find_route(entity.nav.current_block, town)
    if route and #route > 0 then
        entity.nav.route    = route
        entity.nav.waypoint = nav_graph.tile_world_pos(
            entity.nav.current_block, route[1].from_tile[1], route[1].from_tile[2])
        entity.ai.state = "wander"
    end
end

function system:process(entity, dt)
    if entity.faction ~= "adventurer" then return end

    local stat = adventurer_stats[entity.tier]

    -- rank up check
    if stat and stat.xp_to_rank_up and entity.xp >= stat.xp_to_rank_up then
        rank_up(entity)
    end

    local ai_state = entity.ai.state

    -- retreat trigger
    if not entity.retreating
    and (ai_state == "idle" or ai_state == "wander")
    and entity.combat == nil then
        local should_retreat = entity.gold >= GOLD_RETREAT_THRESHOLD
            or (entity.health.current / entity.health.max) <= HEALTH_RETREAT_PCT
        if should_retreat then
            start_retreat(entity)
            return
        end
    end

    -- re-route if retreat was interrupted by combat
    if entity.retreating and entity.nav.current_block ~= system.town_block
    and ai_state == "idle" then
        start_retreat(entity)
        return
    end

    -- dropoff: in town and idle
    if entity.retreating and entity.nav.current_block == system.town_block
    and ai_state == "idle" then
        local gh_x = system.guild_hall_x
        if gh_x and math.abs(entity.position.x - gh_x) > DROPOFF_THRESHOLD then
            -- walk to guild hall within town block
            entity.nav.waypoint = { x = gh_x, y = entity.position.y }
            entity.nav.route    = {}
            entity.ai.state     = "wander"
        else
            -- at guild hall: deposit and heal
            system.guild_gold.value = system.guild_gold.value + entity.gold
            entity.gold             = 0
            entity.health.current   = entity.health.max
            entity.retreating       = false
        end
    end
end

local progression_system = {}
progression_system.system = system

function progression_system.init(town_block, guild_gold_ref, stats, guild_hall_x)
    system.town_block   = town_block
    system.guild_gold   = guild_gold_ref
    system.guild_hall_x = guild_hall_x
    adventurer_stats    = stats
end

return progression_system

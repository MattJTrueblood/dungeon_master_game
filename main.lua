if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local tiny               = require("tiny")
local version            = require("version")
local sprites            = require("src/sprites")
local render_system      = require("src/systems/render_system")
local movement_system    = require("src/systems/movement_system")
local ai_system          = require("src/systems/ai_system")
local spawner_system     = require("src/systems/spawner_system")
local combat_system      = require("src/systems/combat_system")
local chest_system       = require("src/systems/chest_system")
local progression_system = require("src/systems/progression_system")
local camera             = require("src/camera")
local constants          = require("src/constants")
local TILE_SIZE          = constants.TILE_SIZE
local generator          = require("src/dungeon/generator")
local connectivity       = require("src/dungeon/connectivity")
local town_gen           = require("src/town/generator")
local adventurer         = require("src/entities/adventurer")
local hud                = require("src/ui/hud")

local world
local spawn_town_block
local guild_hall_col
local guild_gold = { value = 10 }

function love.load()
    print("loading...")
    love.graphics.setDefaultFilter("nearest", "nearest")
    sprites.load()

    world = tiny.world(
        render_system.block_render_system,
        render_system.entity_render_system,
        movement_system.system,
        ai_system.system,
        spawner_system.monster_system,
        spawner_system.spawner_system,
        spawner_system.boss_spawner_system,
        combat_system.system,
        chest_system.system,
        progression_system.system
    )

    math.randomseed(os.time())

    local NUM_FLOORS = 5
    local floors     = {}
    local all_blocks = {}
    for i = 1, NUM_FLOORS do
        local blocks, entrance = generator.generate_layer(0, (i - 1) * generator.layer_h_px, i)
        floors[i] = { blocks = blocks, entrance = entrance }
        for _, b in ipairs(blocks) do all_blocks[#all_blocks + 1] = b end
    end
    for i = 1, NUM_FLOORS - 1 do
        connectivity.connect_layers(floors[i].blocks, floors[i + 1].blocks, math.random(1, 3))
    end

    local floor_data = {}
    for i = 1, NUM_FLOORS do
        floor_data[i] = { blocks = floors[i].blocks, floor = i }
    end
    generator.place_spawners(floor_data)
    generator.place_chests(floor_data)

    local town_block, house_entities, guild_hall = town_gen.generate(floors[1].entrance)

    world:addEntity(town_block)
    for _, b in ipairs(all_blocks) do world:addEntity(b) end
    for _, house in ipairs(house_entities) do world:addEntity(house) end
    world:addEntity(guild_hall)

    local blocks_by_floor = {}
    for _, b in ipairs(all_blocks) do
        local f = b.floor
        if not blocks_by_floor[f] then blocks_by_floor[f] = {} end
        blocks_by_floor[f][#blocks_by_floor[f] + 1] = b
    end

    local blocks_by_tier = {}
    blocks_by_tier[1] = blocks_by_floor[1] or {}
    blocks_by_tier[2] = {}
    for _, b in ipairs(blocks_by_floor[2] or {}) do blocks_by_tier[2][#blocks_by_tier[2]+1] = b end
    for _, b in ipairs(blocks_by_floor[3] or {}) do blocks_by_tier[2][#blocks_by_tier[2]+1] = b end
    blocks_by_tier[3] = {}
    for _, b in ipairs(blocks_by_floor[4] or {}) do blocks_by_tier[3][#blocks_by_tier[3]+1] = b end
    for _, b in ipairs(blocks_by_floor[5] or {}) do blocks_by_tier[3][#blocks_by_tier[3]+1] = b end

    ai_system.system.blocks          = all_blocks
    ai_system.system.blocks_by_floor = blocks_by_floor
    ai_system.system.blocks_by_tier  = blocks_by_tier

    local gh_x = guild_hall.position.x + TILE_SIZE  -- center tile of 3-wide hall
    progression_system.init(town_block, guild_gold, adventurer.STATS, gh_x)

    spawn_town_block = town_block
    guild_hall_col   = math.floor(guild_hall.position.x / TILE_SIZE) + 2

    camera:set_bounds({
        x1 = 0,
        y1 = town_gen.town_y,
        x2 = generator.layer_w_px,
        y2 = NUM_FLOORS * generator.layer_h_px,
    })
    camera.x = 0
    camera.y = town_gen.town_y
    camera:clamp()

    render_system.init(camera.bounds)

    print("loading complete!")
end

function love.mousepressed(x, y, button)
    if button == 1 then
        local tier, cost = hud.check_click(x, y)
        if tier then
            if guild_gold.value >= cost then
                guild_gold.value = guild_gold.value - cost
                world:addEntity(adventurer.new(spawn_town_block, guild_hall_col, tier))
            end
            return
        end
        camera:start_drag()
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then camera:end_drag() end
end

function love.wheelmoved(x, y)
    local mx, my = love.mouse.getPosition()
    camera:scroll(y, mx, my)
end

function love.mousemoved(x, y, dx, dy)
    if camera.dragging then
        camera:move_drag(dx, dy)
    end
end

function love.update(dt)
    camera:update(dt)
    world:update(dt)
end

function love.draw()
    render_system.draw()
    hud.draw(guild_gold.value)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("v" .. version.major .. "." .. version.minor .. "." .. version.patch, 10, love.graphics.getHeight() - 20)
end

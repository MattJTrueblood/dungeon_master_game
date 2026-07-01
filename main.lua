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

-- shared mutable block list — grows as floors generate
local all_blocks = {}
local floors     = {}  -- floors[n] = { blocks, entrance }
local generated  = {}  -- generated[n] = true

local function generate_floor(n)
    if generated[n] then return end
    generated[n] = true

    local y      = (n - 1) * generator.layer_h_px
    local blocks, entrance = generator.generate_layer(0, y, n)
    floors[n] = { blocks = blocks, entrance = entrance }

    -- connect to floor above
    if floors[n - 1] then
        connectivity.connect_layers(floors[n - 1].blocks, blocks, math.random(1, 3))
    end

    generator.place_spawners({ { blocks = blocks, floor = n } })
    generator.place_chests(  { { blocks = blocks, floor = n } })

    for _, b in ipairs(blocks) do
        world:addEntity(b)
        all_blocks[#all_blocks + 1] = b
    end

    hud.max_floor = n
end

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

    math.randomseed(os.time() * 1000 + math.floor(os.clock() * 10000))

    -- generate only floor 1 at start; subsequent floors generated lazily
    generate_floor(1)

    local town_block, house_entities, guild_hall = town_gen.generate(floors[1].entrance)

    world:addEntity(town_block)
    for _, house in ipairs(house_entities) do world:addEntity(house) end
    world:addEntity(guild_hall)

    ai_system.system.all_blocks         = all_blocks
    ai_system.system.floor_restrictions = hud.floor_restrictions
    movement_system.system.floor_restrictions = hud.floor_restrictions

    local gh_x = guild_hall.position.x + TILE_SIZE
    progression_system.init(town_block, guild_gold, adventurer.STATS, gh_x)

    -- generate next floor when adventurer first steps into floor N
    -- deepest_generated tracks how far down the dungeon actually exists
    ai_system.system.deepest_generated    = 1
    movement_system.system.deepest_generated = 1

    local deepest_stepped = 0
    movement_system.system.on_enter_floor = function(floor_num)
        if not floor_num then return end
        if floor_num > deepest_stepped then
            deepest_stepped = floor_num
            local next_n = floor_num + 1
            generate_floor(next_n)
            ai_system.system.deepest_generated    = next_n
            movement_system.system.deepest_generated = next_n
        end
    end

    spawn_town_block = town_block
    guild_hall_col   = math.floor(guild_hall.position.x / TILE_SIZE) + 2

    camera:set_bounds({
        x1 = 0,
        y1 = town_gen.town_y,
        x2 = generator.layer_w_px,
        y2 = 500 * generator.layer_h_px,  -- effectively infinite
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

local function get_pop_counts()
    local counts = {}
    for _, e in ipairs(progression_system.system.entities) do
        if e.faction == "adventurer" then
            local t = e.tier
            counts[t] = (counts[t] or 0) + 1
        end
    end
    return counts
end

function love.update(dt)
    camera:update(dt)
    world:update(dt)
end

local function outlined_print(text, x, y)
    love.graphics.setColor(0, 0, 0, 1)
    for ox = -1, 1 do
        for oy = -1, 1 do
            if ox ~= 0 or oy ~= 0 then
                love.graphics.print(text, x + ox, y + oy)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(text, x, y)
end

local floor_marker_font = nil

local function draw_floor_markers()
    if not floor_marker_font then
        floor_marker_font = love.graphics.newFont(28)
    end
    local z  = camera.zoom
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    love.graphics.setFont(floor_marker_font)
    love.graphics.setLineWidth(2)

    local font_h = floor_marker_font:getHeight()

    for n = 0, ai_system.system.deepest_generated - 1 do
        local sy = (n * generator.layer_h_px - camera.y) * z
        if sy >= -font_h and sy <= sh + font_h then
            outlined_print(tostring(n),     4, sy - font_h - 2)
            outlined_print(tostring(n + 1), 4, sy + 4)

            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.line(0, sy - 1, 44, sy - 1)
            love.graphics.line(0, sy + 1, 44, sy + 1)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.line(0, sy, 44, sy)
        end
    end

    love.graphics.setLineWidth(1)
    love.graphics.setFont(love.graphics.newFont())
end

function love.draw()
    render_system.draw()
    draw_floor_markers()
    hud.draw(guild_gold.value, get_pop_counts())
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("v" .. version.major .. "." .. version.minor .. "." .. version.patch, 10, love.graphics.getHeight() - 20)
end

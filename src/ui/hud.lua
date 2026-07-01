local sprites   = require("src/sprites")
local constants = require("src/constants")
local TILE_SIZE = constants.TILE_SIZE

local SPRITE_SCALE = 2
local SPRITE_PX    = TILE_SIZE * SPRITE_SCALE  -- 32

local BTN_W     = 110
local BTN_H     = SPRITE_PX + 24  -- 56
local CTRL_W    = 150
local CTRL_GAP  = 4
local BTN_PAD   = 6
local BTN_X_OFF = 10
local AB_W      = 14  -- arrow button width
local AB_H      = 14  -- arrow button height

local TIERS = {
    { tier = 1, label = "Hire", cost = 1,    sprite = "adventurer_1" },
    { tier = 2, label = "Hire", cost = 10,   sprite = "adventurer_2" },
    { tier = 3, label = "Hire", cost = 50,   sprite = "adventurer_3" },
    { tier = 4, label = "Hire", cost = 1000, sprite = "adventurer_4" },
}

local hud = {}

hud.floor_restrictions = {
    [1] = { min = 1, max = 1 },
    [2] = { min = 1, max = 1 },
    [3] = { min = 1, max = 1 },
    [4] = { min = 1, max = 1 },
}
hud.max_floor = 1

local function fmt_floor(v)
    return tostring(math.floor(v))
end

local function section_y(i)
    return BTN_X_OFF + (i - 1) * (BTN_H + BTN_PAD)
end

local function btn_rect(i)
    local sw = love.graphics.getWidth()
    return sw - BTN_W - BTN_X_OFF, section_y(i), BTN_W, BTN_H
end

local function ctrl_rect(i)
    local sw = love.graphics.getWidth()
    return sw - BTN_W - BTN_X_OFF - CTRL_W - CTRL_GAP, section_y(i), CTRL_W, BTN_H
end

-- inline arrow buttons on row 2: [-]min[+]-[-]max[+]
local function arrow_rects(i)
    local cx, cy = ctrl_rect(i)
    local row2_y = cy + 36
    local x = cx + 2
    -- [-] 28px gap for min value [+]  10px sep  [-] 28px gap for max value [+]
    return {
        min_dec = { x = x,               y = row2_y, w = AB_W, h = AB_H },
        min_inc = { x = x + AB_W + 28,   y = row2_y, w = AB_W, h = AB_H },
        max_dec = { x = x + AB_W*2 + 46, y = row2_y, w = AB_W, h = AB_H },
        max_inc = { x = x + AB_W*3 + 74, y = row2_y, w = AB_W, h = AB_H },
    }
end

local function in_rect(mx, my, r)
    return mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h
end

local function draw_arrow_btn(r, label, mx, my)
    local hov = in_rect(mx, my, r)
    love.graphics.setColor(hov and 0.45 or 0.22, hov and 0.45 or 0.22, hov and 0.45 or 0.22, 1)
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 2, 2)
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.rectangle("line", r.x, r.y, r.w, r.h, 2, 2)
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.print(label, r.x + 3, r.y + 1)
end

function hud.draw(gold, pop_counts)
    -- gold display
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 8, 8, 110, 22, 3, 3)
    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.print("Gold: " .. gold .. "g", 14, 12)

    local mx, my = love.mouse.getPosition()

    for i, t in ipairs(TIERS) do
        local rest = hud.floor_restrictions[t.tier]
        local pop  = (pop_counts and pop_counts[t.tier]) or 0

        -- hire button
        local bx, by, bw, bh = btn_rect(i)
        local hov_btn = mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
        love.graphics.setColor(hov_btn and 0.35 or 0.15, hov_btn and 0.35 or 0.15, hov_btn and 0.35 or 0.15, 0.9)
        love.graphics.rectangle("fill", bx, by, bw, bh, 3, 3)
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.rectangle("line", bx, by, bw, bh, 3, 3)
        local sp = sprites.get(t.sprite)
        if sp then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(sp.image, sp.quad, bx + 4, by + 4, 0, SPRITE_SCALE, SPRITE_SCALE)
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(t.label, bx + SPRITE_PX + 10, by + 4)
        love.graphics.setColor(1, 0.85, 0.2, 1)
        love.graphics.print(t.cost .. "gp", bx + SPRITE_PX + 10, by + 18)

        -- ctrl panel background
        local cx, cy, cw, ch = ctrl_rect(i)
        love.graphics.setColor(0.1, 0.1, 0.1, 0.85)
        love.graphics.rectangle("fill", cx, cy, cw, ch, 3, 3)
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.rectangle("line", cx, cy, cw, ch, 3, 3)

        -- row 1: population
        love.graphics.setColor(0.75, 0.75, 0.75, 1)
        love.graphics.print("Pop: " .. pop, cx + 4, cy + 4)
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.print("Can explore floors:", cx + 4, cy + 18)

        -- row 2: floor controls inline
        local ar = arrow_rects(i)
        draw_arrow_btn(ar.min_dec, "-", mx, my)
        love.graphics.setColor(1, 0.85, 0.2, 1)
        love.graphics.print(fmt_floor(rest.min), ar.min_dec.x + AB_W + 6, cy + 37)
        draw_arrow_btn(ar.min_inc, "+", mx, my)
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("to", ar.min_inc.x + AB_W + 4, cy + 37)
        draw_arrow_btn(ar.max_dec, "-", mx, my)
        love.graphics.setColor(1, 0.85, 0.2, 1)
        love.graphics.print(fmt_floor(rest.max), ar.max_dec.x + AB_W + 6, cy + 37)
        draw_arrow_btn(ar.max_inc, "+", mx, my)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function hud.check_click(mx, my)
    for i, t in ipairs(TIERS) do
        local bx, by, bw, bh = btn_rect(i)
        if mx >= bx and mx <= bx + bw and my >= by and my <= by + bh then
            return t.tier, t.cost
        end

        local ar   = arrow_rects(i)
        local rest = hud.floor_restrictions[t.tier]

        if in_rect(mx, my, ar.min_dec) then
            rest.min = math.max(1, rest.min - 1)
            if rest.max ~= math.huge and rest.max < rest.min then rest.max = rest.min end
            return nil, nil
        end
        if in_rect(mx, my, ar.min_inc) then
            rest.min = rest.min + 1
            if rest.max ~= math.huge and rest.max < rest.min then rest.max = rest.min end
            return nil, nil
        end
        if in_rect(mx, my, ar.max_dec) then
            rest.max = math.max(rest.min, rest.max - 1)
            return nil, nil
        end
        if in_rect(mx, my, ar.max_inc) then
            rest.max = math.min(999, rest.max + 1)
            return nil, nil
        end
    end
    return nil, nil
end

return hud

local sprites   = require("src/sprites")
local constants = require("src/constants")
local TILE_SIZE = constants.TILE_SIZE

local SPRITE_SCALE = 2
local SPRITE_PX    = TILE_SIZE * SPRITE_SCALE  -- 32

local BTN_W    = 110
local BTN_H    = SPRITE_PX + 8
local BTN_PAD  = 6
local BTN_X_OFF = 10  -- from right edge

local TIERS = {
    { tier = 1, label = "Hire", cost = 1,  sprite = "adventurer_1" },
    { tier = 2, label = "Hire", cost = 10, sprite = "adventurer_2" },
    { tier = 3, label = "Hire", cost = 50, sprite = "adventurer_3" },
}

local function btn_rect(i)
    local sw = love.graphics.getWidth()
    local x  = sw - BTN_W - BTN_X_OFF
    local y  = BTN_X_OFF + (i - 1) * (BTN_H + BTN_PAD)
    return x, y, BTN_W, BTN_H
end

local hud = {}

function hud.draw(gold)
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 8, 8, 110, 22, 3, 3)
    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.print("Gold: " .. gold .. "g", 14, 12)

    local mx, my = love.mouse.getPosition()

    for i, t in ipairs(TIERS) do
        local x, y, w, h = btn_rect(i)
        local hovered = mx >= x and mx <= x + w and my >= y and my <= y + h

        love.graphics.setColor(hovered and 0.35 or 0.15, hovered and 0.35 or 0.15, hovered and 0.35 or 0.15, 0.9)
        love.graphics.rectangle("fill", x, y, w, h, 3, 3)
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.rectangle("line", x, y, w, h, 3, 3)

        -- sprite
        local sp = sprites.get(t.sprite)
        if sp then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(sp.image, sp.quad, x + 4, y + 4, 0, SPRITE_SCALE, SPRITE_SCALE)
        end

        -- label and cost
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(t.label, x + SPRITE_PX + 10, y + 4)
        love.graphics.setColor(1, 0.85, 0.2, 1)
        love.graphics.print(t.cost .. "gp", x + SPRITE_PX + 10, y + 18)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- returns tier clicked (1/2/3) or nil
function hud.check_click(mx, my)
    for i, t in ipairs(TIERS) do
        local x, y, w, h = btn_rect(i)
        if mx >= x and mx <= x + w and my >= y and my <= y + h then
            return t.tier, t.cost
        end
    end
    return nil, nil
end

return hud

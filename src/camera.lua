local constants = require("src/constants")
local TILE_SIZE = constants.TILE_SIZE
local BUFFER    = 3 * TILE_SIZE
local ELASTIC   = 4 * TILE_SIZE
local MAX_ZOOM  = 4.0

local camera = {
    x            = 0,
    y            = 0,
    zoom         = 1,
    target_zoom  = 1,
    zoom_pivot   = { x = 0, y = 0 },
    bounds       = { x1 = 0, y1 = 0, x2 = 0, y2 = 0 },
    vel_x        = 0,
    vel_y        = 0,
    drag_vel_x   = 0,
    drag_vel_y   = 0,
    drag_accum_x = 0,
    drag_accum_y = 0,
    dragging     = false,
}

local function view_bounds(cam)
    local sw, sh = love.graphics.getDimensions()
    local vw = sw / cam.zoom
    local vh = sh / cam.zoom
    return
        cam.bounds.x1 - BUFFER,
        cam.bounds.y1 - BUFFER,
        cam.bounds.x2 - vw + BUFFER,
        cam.bounds.y2 - vh + BUFFER
end

local function min_zoom(bounds)
    local sw = love.graphics.getWidth()
    return sw / (bounds.x2 - bounds.x1 + 6 * TILE_SIZE)
end

function camera:set_bounds(bounds)
    self.bounds      = bounds
    local mz         = min_zoom(bounds)
    self.zoom        = mz
    self.target_zoom = mz
end

function camera:clamp()
    local lo_x, lo_y, hi_x, hi_y = view_bounds(self)
    self.x = math.max(lo_x, math.min(self.x, hi_x))
    self.y = math.max(lo_y, math.min(self.y, hi_y))
end

function camera:start_drag()
    self.dragging    = true
    self.vel_x       = 0
    self.vel_y       = 0
    self.drag_vel_x  = 0
    self.drag_vel_y  = 0
    self.drag_accum_x = 0
    self.drag_accum_y = 0
end

function camera:end_drag()
    if not self.dragging then return end
    self.dragging = false
    self.vel_x    = self.drag_vel_x
    self.vel_y    = self.drag_vel_y
end

function camera:move_drag(dx, dy)
    local wx = -dx / self.zoom
    local wy = -dy / self.zoom
    local lo_x, lo_y, hi_x, hi_y = view_bounds(self)

    local elastic_world = ELASTIC / self.zoom
    local function elastic_apply(pos, delta, lo, hi)
        local new_pos = pos + delta
        local over = 0
        if new_pos < lo then over = lo - new_pos
        elseif new_pos > hi then over = new_pos - hi end
        if over > 0 then delta = delta * math.max(0, 1 - over / elastic_world) end
        return pos + delta
    end

    local prev_x, prev_y = self.x, self.y
    if lo_x < hi_x then self.x = elastic_apply(self.x, wx, lo_x, hi_x) end
    self.y = elastic_apply(self.y, wy, lo_y, hi_y)
    self.drag_accum_x = self.drag_accum_x + (self.x - prev_x)
    self.drag_accum_y = self.drag_accum_y + (self.y - prev_y)
end

function camera:scroll(ticks, mx, my)
    self.target_zoom  = math.max(min_zoom(self.bounds), math.min(MAX_ZOOM, self.target_zoom * (1.1 ^ ticks)))
    self.zoom_pivot.x = mx
    self.zoom_pivot.y = my
end

function camera:update(dt)
    if math.abs(self.zoom - self.target_zoom) > 0.0001 then
        local old_zoom = self.zoom
        self.zoom = self.target_zoom + (self.zoom - self.target_zoom) * math.exp(-12 * dt)
        local dz = 1 / old_zoom - 1 / self.zoom
        self.x = self.x + self.zoom_pivot.x * dz
        self.y = self.y + self.zoom_pivot.y * dz
    else
        self.zoom = self.target_zoom
    end

    if self.dragging and dt > 0 then
        local vx = self.drag_accum_x / dt
        local vy = self.drag_accum_y / dt
        self.drag_vel_x  = self.drag_vel_x * 0.4 + vx * 0.6
        self.drag_vel_y  = self.drag_vel_y * 0.4 + vy * 0.6
        self.drag_accum_x = 0
        self.drag_accum_y = 0
    end

    if not self.dragging then
        self.x = self.x + self.vel_x * dt
        self.y = self.y + self.vel_y * dt

        local friction = math.exp(-9 * dt)
        self.vel_x = self.vel_x * friction
        self.vel_y = self.vel_y * friction

        local lo_x, lo_y, hi_x, hi_y = view_bounds(self)
        local tx = math.max(lo_x, math.min(self.x, hi_x))
        local ty = math.max(lo_y, math.min(self.y, hi_y))
        if tx ~= self.x or ty ~= self.y then
            local snap = 1 - math.exp(-20 * dt)
            self.x = self.x + (tx - self.x) * snap
            self.y = self.y + (ty - self.y) * snap
            self.vel_x = self.vel_x * (1 - snap)
            self.vel_y = self.vel_y * (1 - snap)
        end
    end
end

return camera

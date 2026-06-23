local camera = { x = 0, y = 0 }

function camera:apply()
    love.graphics.push()
    love.graphics.translate(-self.x, -self.y)
end

function camera:reset()
    love.graphics.pop()
end

return camera

local ffi = require("ffi")

ffi.cdef[[
    typedef struct {
        float x, y;
        uint8_t r, g, b, a;
    } Vertex;

    typedef struct {
        float x, y, z;
        float vx, vy, vz;
    } Entity3D;
]]

RLengine = {
    _VERSION = "2.0 MaxPerf 3D",
    count = 0,
    maxCount = 2000000,
    fov = 500,
    bounds = {w = 1280, h = 720},
    cam = {x = 0, y = 0, z = -600, pitch = 0, yaw = 0},
    light = {x = 0, y = 0, z = 0}
}

function RLengine.init(w, h)
    RLengine.bounds.w = w or love.graphics.getWidth()
    RLengine.bounds.h = h or love.graphics.getHeight()

    local vSize = ffi.sizeof("Vertex")
    local eSize = ffi.sizeof("Entity3D")

    RLengine.data = love.data.newByteData(vSize * RLengine.maxCount)
    RLengine.entityData = love.data.newByteData(eSize * RLengine.maxCount)

    RLengine.ptr = ffi.cast("Vertex*", RLengine.data:getFFIPointer())
    RLengine.entities = ffi.cast("Entity3D*", RLengine.entityData:getFFIPointer())

    local layout = {
        {"VertexPosition", "float", 2},
        {"VertexColor", "byte", 4}
    }

    RLengine.mesh = love.graphics.newMesh(layout, RLengine.maxCount, "points", "stream")
    RLengine.addEntities(500000)
end

function RLengine.addEntities(amount)
    local target = math.min(RLengine.maxCount, RLengine.count + amount)
    local entities = RLengine.entities

    for i = RLengine.count, target - 1 do
        local e = entities[i]
        e.x = math.random(-600, 600)
        e.y = math.random(-600, 600)
        e.z = math.random(-600, 600)
        e.vx = math.random(-80, 80)
        e.vy = math.random(-80, 80)
        e.vz = math.random(-80, 80)
    end

    RLengine.count = target
end

function RLengine.removeEntities(amount)
    RLengine.count = math.max(0, RLengine.count - amount)
end

function RLengine.update(dt)
    local count = RLengine.count
    if count == 0 then return end

    local ptr = RLengine.ptr
    local entities = RLengine.entities

    local cx = RLengine.bounds.w * 0.5
    local cy = RLengine.bounds.h * 0.5
    local fov = RLengine.fov

    local cam = RLengine.cam
    local camX, camY, camZ = cam.x, cam.y, cam.z
    local cosY, sinY = math.cos(-cam.yaw), math.sin(-cam.yaw)
    local cosP, sinP = math.cos(-cam.pitch), math.sin(-cam.pitch)

    local isLmb = love.mouse.isDown(1)
    local damp = 1.0 - dt * 0.2

    if isLmb then
        local forceBase = 10000000 * dt
        for i = 0, count - 1 do
            local e = entities[i]
            local v = ptr[i]

            local x, y, z = e.x, e.y, e.z
            local vx, vy, vz = e.vx, e.vy, e.vz

            local dx, dy, dz = -x, -y, -z
            local distSq = dx * dx + dy * dy + dz * dz + 4000
            local force = forceBase / distSq

            vx = (vx + dx * force) * damp
            vy = (vy + dy * force) * damp
            vz = (vz + dz * force) * damp

            x = x + vx * dt
            y = y + vy * dt
            z = z + vz * dt

            if x < -800 then x = -800; vx = -vx * 0.75 elseif x > 800 then x = 800; vx = -vx * 0.75 end
            if y < -800 then y = -800; vy = -vy * 0.75 elseif y > 800 then y = 800; vy = -vy * 0.75 end
            if z < -800 then z = -800; vz = -vz * 0.75 elseif z > 800 then z = 800; vz = -vz * 0.75 end

            e.x = x; e.y = y; e.z = z
            e.vx = vx; e.vy = vy; e.vz = vz

            local tx = x - camX
            local ty = y - camY
            local tz = z - camZ

            local x1 = tx * cosY - tz * sinY
            local z1 = tx * sinY + tz * cosY

            local y2 = ty * cosP - z1 * sinP
            local z2 = ty * sinP + z1 * cosP

            if z2 > 10 then
                local invZ = fov / z2
                v.x = cx + x1 * invZ
                v.y = cy + y2 * invZ

                local dSq = x*x + y*y + z*z
                local intensity = 1.0 - (dSq * 0.000001)
                if intensity < 0.1 then intensity = 0.1 end

                local depthFog = 1.0 - (z2 * 0.0004)
                if depthFog < 0 then depthFog = 0 end

                local br = intensity * depthFog
                v.r = 60 + (195 * br)
                v.g = 130 + (125 * br)
                v.b = 255 * br
                v.a = 255 * depthFog
            else
                v.x = -9999
                v.y = -9999
                v.a = 0
            end
        end
    else
        for i = 0, count - 1 do
            local e = entities[i]
            local v = ptr[i]

            local x, y, z = e.x, e.y, e.z
            local vx, vy, vz = e.vx, e.vy, e.vz

            vx = vx * damp
            vy = vy * damp
            vz = vz * damp

            x = x + vx * dt
            y = y + vy * dt
            z = z + vz * dt

            if x < -800 then x = -800; vx = -vx * 0.75 elseif x > 800 then x = 800; vx = -vx * 0.75 end
            if y < -800 then y = -800; vy = -vy * 0.75 elseif y > 800 then y = 800; vy = -vy * 0.75 end
            if z < -800 then z = -800; vz = -vz * 0.75 elseif z > 800 then z = 800; vz = -vz * 0.75 end

            e.x = x; e.y = y; e.z = z
            e.vx = vx; e.vy = vy; e.vz = vz

            local tx = x - camX
            local ty = y - camY
            local tz = z - camZ

            local x1 = tx * cosY - tz * sinY
            local z1 = tx * sinY + tz * cosY

            local y2 = ty * cosP - z1 * sinP
            local z2 = ty * sinP + z1 * cosP

            if z2 > 10 then
                local invZ = fov / z2
                v.x = cx + x1 * invZ
                v.y = cy + y2 * invZ

                local dSq = x*x + y*y + z*z
                local intensity = 1.0 - (dSq * 0.000001)
                if intensity < 0.1 then intensity = 0.1 end

                local depthFog = 1.0 - (z2 * 0.0004)
                if depthFog < 0 then depthFog = 0 end

                local br = intensity * depthFog
                v.r = 60 + (195 * br)
                v.g = 130 + (125 * br)
                v.b = 255 * br
                v.a = 255 * depthFog
            else
                v.x = -9999
                v.y = -9999
                v.a = 0
            end
        end
    end

    RLengine.mesh:setVertices(RLengine.data, 1, count)
end

function RLengine.draw()
    if RLengine.count > 0 then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setPointSize(2)
        RLengine.mesh:setDrawRange(1, RLengine.count)
        love.graphics.draw(RLengine.mesh)
    end

    local memMB = collectgarbage("count") / 1024
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 10, 10, 480, 190)

    love.graphics.setColor(0, 1, 0.5)
    love.graphics.print("RLengine 2.0 | MAX PERFORMANCE 3D", 20, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("FPS: " .. love.timer.getFPS() .. " (" .. string.format("%.2f", 1000 / math.max(1, love.timer.getFPS())) .. " ms)", 20, 45)
    love.graphics.print("Active 3D Entities: " .. RLengine.count .. " / " .. RLengine.maxCount, 20, 65)
    love.graphics.print("Lua Memory: " .. string.format("%.2f MB", memMB), 20, 85)
    love.graphics.print("Camera Pos: " .. string.format("%.0f, %.0f, %.0f", RLengine.cam.x, RLengine.cam.y, RLengine.cam.z), 20, 105)
    love.graphics.print("[RMB Drag] Rotate Camera 3D (Pitch/Yaw)", 20, 125)
    love.graphics.print("[WASD + Space/Shift] Move 3D Camera", 20, 145)
    love.graphics.print("[LMB] Center Gravitational Force Field", 20, 165)
end

function love.load()
    love.window.setMode(1280, 720, {resizable = false, vsync = false})
    love.window.setTitle("RLengine 2.0 - Super Optimized 3D")
    RLengine.init()
end

function love.update(dt)
    local cam = RLengine.cam
    local speed = 600 * dt

    local forwardX = math.sin(cam.yaw) * speed
    local forwardZ = math.cos(cam.yaw) * speed
    local rightX = math.cos(cam.yaw) * speed
    local rightZ = -math.sin(cam.yaw) * speed

    if love.keyboard.isDown("w") then
        cam.x = cam.x + forwardX
        cam.z = cam.z + forwardZ
    end
    if love.keyboard.isDown("s") then
        cam.x = cam.x - forwardX
        cam.z = cam.z - forwardZ
    end
    if love.keyboard.isDown("a") then
        cam.x = cam.x - rightX
        cam.z = cam.z - rightZ
    end
    if love.keyboard.isDown("d") then
        cam.x = cam.x + rightX
        cam.z = cam.z + rightZ
    end
    if love.keyboard.isDown("space") then
        cam.y = cam.y + speed
    end
    if love.keyboard.isDown("lshift") then
        cam.y = cam.y - speed
    end

    RLengine.update(dt)
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) then
        local cam = RLengine.cam
        cam.yaw = cam.yaw + dx * 0.005
        cam.pitch = math.max(-1.5, math.min(1.5, cam.pitch - dy * 0.005))
    end
end

function love.draw()
    RLengine.draw()
end

function love.keypressed(key)
    if key == "up" then
        RLengine.addEntities(250000)
    elseif key == "down" then
        RLengine.removeEntities(250000)
    end
end
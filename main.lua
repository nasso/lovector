--[[
MIT License

Copyright (c) 2019 nasso <nassomails ~ at ~ gmail {dot} com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local lovector = require "lovector"

local oldmousex = nil
local oldmousey = nil

local cameraX = 0
local cameraY = -140
local cameraXVel = 0
local cameraYVel = 0
local cameraZoomTarget = 0.8
local cameraZoom = cameraZoomTarget

local graphics = {}

function love.load()
    -- Windo settings
    love.window.setMode(1280, 960, {
        minheight = 30;
        minwidth = 400;
        msaa = 4;
        resizable = true;
        vsync = false;
    })

    love.graphics.setBackgroundColor(1, 1, 1)

    --- Basic demo
    -- Create a path
    -- Most methods return "self", so you can chain method calls
    local roof_path = lovector.PathBuilder()
        :move_to(50, 140)
        :line_to(150, 60)
        :line_to(250, 140)
        :close_path()

    -- Create a vector graphics image with "Graphics"
    -- It dynamically generates a LÖVE draw function we can use later
    -- Most methods return "self"
    graphics[1] = lovector.Graphics()
        -- Set line width
        :set_line_width(10)

        -- Wall
        :rect(75, 140, 150, 110)
        :stroke_path()

        -- Door
        :begin_path()
        :rect(130, 190, 40, 60)
        :fill_path()

        -- You can also use a manually created Path!
        :stroke_path(roof_path)

    --- SVG loading demo
    -- (it just returns a "Graphics")
    graphics[2] = lovector.SVG("demo_files/path.svg")

    -- tiggie!
    graphics[3] = lovector.SVG("demo_files/ghostscript-tiger.svg")
end

function love.update(dt)
    -- Cool, juicy camera control
    cameraZoom = cameraZoom + (cameraZoomTarget - cameraZoom) * 10 * dt

    local mousex, mousey = love.mouse.getPosition()

    if love.mouse.isDown(1) and oldmousex ~= nil then
        cameraXVel = (mousex - oldmousex) / dt
        cameraYVel = (mousey - oldmousey) / dt
    end

    oldmousex = mousex
    oldmousey = mousey

    cameraX = cameraX - cameraXVel * dt / cameraZoom
    cameraY = cameraY - cameraYVel * dt / cameraZoom

    if not love.mouse.isDown(1) then
        cameraXVel = cameraXVel - cameraXVel * 10 * dt
        cameraYVel = cameraYVel - cameraYVel * 10 * dt
    end
end

function love.draw()
    local w, h = love.graphics.getDimensions()

    -- Move to camera space
    love.graphics.push()
    love.graphics.translate(w/2, h/2)
    love.graphics.scale(cameraZoom)
    love.graphics.translate(-w/2, -h/2)
    love.graphics.translate(-cameraX, -cameraY)

    -- Draw all our graphics!
    graphics[1]:draw(0, -300)
    graphics[2]:draw(0, 0)
    graphics[3]:draw(800, 50, 400)

    -- Get out of the camera
    love.graphics.pop()

    -- Display debug info
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 160, 160)

    love.graphics.setColor(1, 1, 1, 1)

    -- Stats
    local stats = love.graphics.getStats()
    love.graphics.print(tostring(love.timer.getFPS()) .. " FPS | " .. tostring(math.floor(love.timer.getDelta() * 100000) / 100) .. " ms", 10, 10)
    love.graphics.print("Draw calls: " .. tostring(stats.drawcalls), 10, 30)
    love.graphics.print("Canvas switches: " .. tostring(stats.canvasswitches), 10, 50)
    love.graphics.print("Texture memory: " .. tostring(stats.texturememory) .. " B", 10, 70)
    love.graphics.print("Images: " .. tostring(stats.images), 10, 90)
    love.graphics.print("Canvases: " .. tostring(stats.canvases), 10, 110)
    love.graphics.print("Fonts: " .. tostring(stats.fonts), 10, 130)
end

function love.keypressed(k)
    -- Quit on escape
    if k == "escape" then
        love.event.quit()
    end
end

function love.wheelmoved(x, y)
    -- Zoom control with the wheel
    cameraZoomTarget = math.max(cameraZoomTarget * (y < 0 and 0.9 or 1.1), 0.1)
end

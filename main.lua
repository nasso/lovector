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

local cameraX = -720
local cameraY = -250
local cameraXVel = 0
local cameraYVel = 0
local cameraZoomTarget = 1
local cameraZoom = 1

local pics = {}

function love.load()
	love.window.setMode(1280, 960, {
		minheight = 30;
		minwidth = 400;
		msaa = 4;
		resizable = true;
		vsync = false;
	})

	love.graphics.setBackgroundColor(1, 1, 1)

	-- <path> demo
	pics[1] = lovector.SVG("demo_files/path.svg")

	-- tiggie!
	pics[2] = lovector.SVG("demo_files/ghostscript-tiger.svg")
end

function love.update(dt)
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

	love.graphics.push()
	love.graphics.translate(w/2, h/2)
	love.graphics.scale(cameraZoom)
	love.graphics.translate(-w/2, -h/2)
	love.graphics.translate(-cameraX, -cameraY)

	pics[1]:draw(0, 0)
	pics[2]:draw(800, 50, 400)

	love.graphics.pop()

	love.graphics.setColor(0, 0, 0, 1)

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
	if k == "escape" then
		love.event.quit()
	end
end

function love.wheelmoved(x, y)
	cameraZoomTarget = math.max(cameraZoomTarget * (y < 0 and 0.9 or 1.1), 0.1)
end

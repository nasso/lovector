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
		resizable = true;
		vsync = false;
		minwidth = 400;
		minheight = 30;
	})

	love.graphics.setBackgroundColor(1, 1, 1)

	-- <path> demo
	pics[1] = lovector.loadsvg("demo_files/path.svg", {
		--  - That's the default value for bezier_depth:
		-- bezier_depth = 5;

		--  - Faster, but less accurate, enabling this option
		--      will use LOVE2D's filling function to fill polygons.
		--      The default is false, and will use the 'evenodd' rule.
		--      'evenodd' isn't the default according to the SVG
		--      specification, it should be 'nonzero' but this feature
		--      isn't implemented yet; this might cause incorrect results.
		-- use_love_fill = true;
	})

	-- tiggie!
	-- pics[2] = lovector.loadsvg("demo_files/ghostscript-tiger.svg")
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

	-- draw any scheduled SVGs
	pics[1]:draw(0, 0, 1)
	-- pics[2]:draw(550, 100, 500)

	love.graphics.pop()
end

function love.keypressed(k)
	if k == "escape" then
		love.event.quit()
	end
end

function love.wheelmoved(x, y)
	cameraZoomTarget = math.max(cameraZoomTarget * (y < 0 and 0.9 or 1.1), 0.1)
end
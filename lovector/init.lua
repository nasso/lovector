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

local cwd = (...):match('(.-lovector).*$') .. "."

local svgparse = require(cwd .. "svgparse")

local lovector = {}

lovector.SVG = {}
lovector.SVG.__index = lovector.SVG

function lovector.SVG:draw(x, y, sx, sy)
    if x  == nil then x  = 0  end
    if y  == nil then y  = 0  end
    if sx == nil then sx = 1  end
    if sy == nil then sy = sx end

    -- a viewport width/height of 0 disables drawing
    if self.viewport == nil or (self.viewport.width ~= 0 and self.viewport.height ~= 0) then
        -- push graphics settings
        love.graphics.push()

        -- position
        love.graphics.translate(x or 0, y or 0)

        -- scale
        if sx ~= nil then
            love.graphics.scale(sx, sy)
        end

        -- SVG viewBox handling
        if self.viewport ~= nil then
            love.graphics.translate(-self.viewport.minx, -self.viewport.miny)
            love.graphics.scale(self.width / self.viewport.width, self.height / self.viewport.height)
        end

        -- draw
        self.draw_function(self.extdata)

        -- reset graphics
        love.graphics.pop()
    end
end

function lovector.loadsvg(svg, options)
    -- if the svg argument is a path, load it
    if not svg:match("<?xml") then
        local contents, err = love.filesystem.read(svg)

        if contents == nil then
            error(err)
        end

        svg = contents
    end

    -- parse
    svg = svgparse(svg, options)

    return setmetatable(svg, lovector.SVG)
end

return lovector

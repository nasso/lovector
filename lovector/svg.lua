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

local cwd = (...):match('(.-)[^%.]+$')

local DOM = require(cwd .. "dom")

local DEFAULT_OPTIONS = {
    bezier_depth = 5;
    use_love_fill = true;
}

local SVG = {}
SVG.__index = SVG

SVG.mt = {}
SVG.mt.__index = SVG.mt
setmetatable(SVG, SVG.mt)

function SVG.mt.__call(_, svg, options)
    -- Arg check
    assert(type(svg) == "string", "\"svg\" should be a string, but is " .. type(svg))

    if options == nil then
        options = {}
    end

    for k, v in pairs(DEFAULT_OPTIONS) do
        if options[k] == nil then
            options[k] = v
        end
    end

    -- if the svg argument is a path, load it
    if not svg:match("<?xml") then
        local contents, err = love.filesystem.read(svg)

        if contents == nil then
            error(err)
        end

        svg = contents
    end

    -- Parse XML
    local document = DOM.Document(svg)

    -- SVG object
    local svg = {
        width = 0;
        height = 0;
        viewport = nil;
        extdata = {};
        draw_function = 'local extdata = ...\n';
    }

    -- Parse SVG

    -- Create draw_function
    svg.draw_function = assert(loadstring(svg.draw_function))

    return setmetatable(svg, SVG)
end

function SVG:draw(x, y, sx, sy)
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

return SVG

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

local cwd = (...):match('(.*lovector).-$') .. "."
local PathBuilder = require(cwd .. "pathbuilder")
local common = require(cwd .. "svg.common")

local renderer = {}

function renderer:empty(svg, options)
    local x = tonumber(common.get_attr(self, "x", "0"), 10)
    local y = tonumber(common.get_attr(self, "y", "0"), 10)
    local width = tonumber(common.get_attr(self, "width", "-1"), 10)
    local height = tonumber(common.get_attr(self, "height", "-1"), 10)
    local rx = tonumber(common.get_attr(self, "rx", "-1"), 10)
    local ry = tonumber(common.get_attr(self, "ry", "-1"), 10)

    -- the bad stuff
    if width <= 0 or height <= 0 then
        return ""
    end

    -- the rounded stuff
    -- they tell us everything at https://www.w3.org/TR/SVG11/shapes.html#RectElementRXAttribute
    -- for us, a "properly set" value is >= 0
    if rx < 0 and ry < 0 then
        rx = 0
        ry = 0
    elseif rx >= 0 and ry < 0 then
        ry = rx
    elseif rx < 0 and ry >= 0 then
        rx = ry
    end

    if rx > width / 2 then
        rx = width / 2
    end

    if ry > height / 2 then
        ry = height / 2
    end

    local path = PathBuilder(options)

    path:move_to(x + rx, y)
    path:line_to(x + width - rx, y)

    if rx ~= 0 and ry ~= 0 then
        path:elliptical_arc_to(rx, ry, 0, false, true, x + width, y + ry)
    end

    path:line_to(x + width, y + height - ry)

    if rx ~= 0 and ry ~= 0 then
        path:elliptical_arc_to(rx, ry, 0, false, true, x + width - rx, y + height)
    end

    path:line_to(x + rx, y + height)

    if rx ~= 0 and ry ~= 0 then
        path:elliptical_arc_to(rx, ry, 0, false, true, x, y + height - ry)
    end

    path:line_to(x, y + ry)

    if rx ~= 0 and ry ~= 0 then
        path:elliptical_arc_to(rx, ry, 0, false, true, x + rx, y)
    end

    path:close_path()

    svg.graphics:draw_path(path)
end

return renderer

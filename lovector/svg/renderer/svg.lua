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
local common = require(cwd .. "svg.common")

local renderer = {}

function renderer:open(svg, options)
    local width = common.get_attr(self, "width")
    local height = common.get_attr(self, "height")
    local viewBox = common.get_attr(self, "viewBox")

    if width ~= nil then
        width = tonumber(width, 10)
    end

    if height ~= nil then
        height = tonumber(height, 10)
    end

    if viewBox ~= nil then
        local next_num = string.gmatch(viewBox, "%-?[^%s,%-]+")

        viewBox = {
            minx = next_num();
            miny = next_num();
            width = next_num();
            height = next_num();
        }

        -- 100%
        if width == nil then
            width = viewBox.width
        end

        -- 100%
        if height == nil then
            height = viewBox.height
        end
    end

    -- The top level SVG element sets some properties in the svg object
    if self.parent == nil then
        svg.width = width
        svg.height = height
        svg.viewBox = viewBox
    end

    return ""
end

return renderer

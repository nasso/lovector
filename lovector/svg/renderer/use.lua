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
local DOM = require(cwd .. "svg.dom")
local common = require(cwd .. "svg.common")

local renderer = {}

function renderer:empty(svg, options)
    local x = tonumber(common.get_attr(self, "x", "0"), 10)
    local y = tonumber(common.get_attr(self, "y", "0"), 10)
    local width = common.get_attr(self, "width")
    local height = common.get_attr(self, "height")
    local href = common.get_attr(self, "href", common.get_attr(self, "xlink:href"))

    -- href check
    if href == nil then
        return ""
    end

    -- width check
    if width ~= nil then
        width = tonumber(width, 10)

        if width <= 0 then
            return ""
        end
    end

    -- height check
    if height ~= nil then
        height = tonumber(height, 10)

        if height <= 0 then
            return ""
        end
    end

    -- get the target element's ID
    href = href:match("#(.+)")

    if href == nil then
        return ""
    end

    -- get the actual target element
    href = svg.document:get_element_by_id(href)

    if href == nil then
        return ""
    end

    -- clone the element
    href = href:clone()
    href:set_attribute("id", nil)

    -- remove arguments we don't wanna keep
    self.attributes["x"] = nil
    self.attributes["y"] = nil
    self.attributes["width"] = nil
    self.attributes["height"] = nil
    self.attributes["href"] = nil
    self.attributes["xlink:href"] = nil

    -- generate the <g> that will replace this <use>
    local g = DOM.Element("g", self.attributes)

    -- add transform
    if x ~= 0 or y ~= 0 then
        g:set_attribute("transform", common.get_attr(g, "transform", "") .. " translate(" .. x .. ", " .. y .. ")")
    end

    -- add the cloned element
    g:append_child(href)

    -- render the element
    common.gen(svg, g, options)
end

return renderer

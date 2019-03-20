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

local utils = {}

function utils.xml_tostring(element, indent_string, lvl)
    if lvl == nil then lvl = 0 end
    if indent_string == nil then indent_string = "    " end

    local result = ""

    local indent = string.rep(indent_string, lvl)

    local attr = ""

    if element.attributes ~= nil then
        for k, v in pairs(element.attributes) do
            attr = attr .. " " .. k .. "=\"" .. tostring(v) .. "\""
        end
    end

    -- empty element
    if element.children == nil then
        result = result .. indent .. "<" .. element.name .. attr .. " />\n"

    -- regular element
    else
        result = result .. indent .. "<" .. element.name .. attr .. ">\n"

        for _, v in ipairs(element.children) do
            result = result .. utils.xml_tostring(v, indent_string, lvl + 1) .. "\n"
        end

        result = result .. indent .. "</" .. element.name .. ">\n"
    end

    return result:sub(1, #result - 1)
end

return utils

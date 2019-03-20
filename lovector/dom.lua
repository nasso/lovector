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

local DOM = {}

-- Private constants
local TOKEN_LIST = {
    [""] = "%s*";
    ["Name"] = "([:A-Z_a-z][:A-Z_a-z0-9%-%.]*)";
    ["Eq"] = "=";
    ["AttValue"] = { "\"(.-)\"", "'(.-)'" };
}

for k, v in pairs(TOKEN_LIST) do
    if k ~= "" then
        if type(v) == "table" then
            for i, vi in ipairs(v) do
                v[i] = "^" .. TOKEN_LIST[""] .. vi .. TOKEN_LIST[""]
            end

        else
            TOKEN_LIST[k] = "^" .. TOKEN_LIST[""] .. v .. TOKEN_LIST[""]
        end
    end
end

-- Parse attributes
local function _attributes(text)
    local attributes = {}

    local i, j = 0, 0
    local name, value = nil

    while true do
        _, i, name = text:find(TOKEN_LIST["Name"], i + 1)

        -- If we didn't find a name, it's over
        if i == nil then
            break
        end

        -- Look for the =
        _, j = text:find(TOKEN_LIST["Eq"], i + 1)

        -- If we didn't find the =, just mark the attribute as true
        if j == nil then
            attributes[name] = true

        -- If we found the =
        else
            -- we know j ~= nil, make it replace i
            i = j

            -- Look for the value!
            for _, pattern in ipairs(TOKEN_LIST["AttValue"]) do
                _, j, value = text:find(pattern, i + 1)

                -- whenever the value is (finally) found
                if value ~= nil then
                    attributes[name] = value
                    i = j
                    break
                end
            end
        end
    end

    return attributes
end

-- Converts an Element to a string
local function element_tostring(element, indent_string, lvl)
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
            result = result .. element_tostring(v, indent_string, lvl + 1) .. "\n"
        end

        result = result .. indent .. "</" .. element.name .. ">\n"
    end

    return result:sub(1, #result - 1)
end

-- Document
DOM.Document = {}
DOM.Document.__index = DOM.Document

DOM.Document.mt = {}
DOM.Document.mt.__index = DOM.Document.mt
setmetatable(DOM.Document, DOM.Document.mt)

function DOM.Document.mt.__call(_, source)
    local self = {}

    self.root = nil
    self.idmap = {}

    local current_parent = self.root

    for tag, closes, name, attributes, empty in source:gmatch("(<(/?)([:A-Z_a-z][:A-Z_a-z0-9%-%.]*)(.-)(/?)>)") do
        closes = closes == "/"
        empty = empty == "/"

        if not closes then
            local element = DOM.Element(name, _attributes(attributes))
            element.parent = current_parent

            -- Cache id
            if element:getAttribute("id") ~= nil then
                self.idmap[element:getAttribute("id")] = element
            end

            if current_parent ~= nil then
                current_parent:appendChild(element)
            else
                assert(self.root == nil, "Can only have 1 root element")

                self.root = element
            end

            if not empty then
                current_parent = element
            end
        else
            assert(current_parent ~= nil, "Found a start-tag without any matching end-tag")
            current_parent = current_parent.parent
        end
    end

    assert(current_parent == nil, "Missing end-tag")

    return setmetatable(self, DOM.Document)
end

function DOM.Document:getElementById(id)
    return self.idmap[id]
end

function DOM.Document:__tostring()
    return tostring(self.root)
end

-- Element
DOM.Element = {}
DOM.Element.__index = DOM.Element

DOM.Element.mt = {}
DOM.Element.mt.__index = DOM.Element.mt
setmetatable(DOM.Element, DOM.Element.mt)

function DOM.Element.mt.__call(_, name, attributes, children)
    return setmetatable({
        parent = nil;
        name = name;
        attributes = attributes;
        children = children;
    }, DOM.Element)
end

function DOM.Element:insertChild(i, element)
    if self.children == nil then
        self.children = {}
    end

    table.insert(self.children, i, element)
end

function DOM.Element:appendChild(element)
    if self.children == nil then
        self.children = {}
    end

    table.insert(self.children, element)
end

function DOM.Element:getAttribute(name, inherit)
    local value = nil
    local this = self

    repeat
        if this.attributes ~= nil then
            value = this.attributes[name]
        end

        this = this.parent

        -- Repeat if the attribute is to be inherited
    until not (inherit and value == nil and this ~= nil)

    return value
end

function DOM.Element:__tostring()
    return element_tostring(self)
end

return DOM

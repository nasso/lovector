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
local function parse_attributes(text)
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
    self.linear_list = {}
    self.idmap = {}

    local current_parent = self.root

    for tag, closes, name, attributes, empty in source:gmatch("(<(/?)([:A-Z_a-z][:A-Z_a-z0-9%-%.]*)(.-)(/?)>)") do
        closes = closes == "/"
        empty = empty == "/"

        if not closes then
            local element = DOM.Element(name, parse_attributes(attributes))
            element.parent = current_parent

            -- Put it in the linear element table
            table.insert(self.linear_list, element)

            -- Cache id
            if element:get_attribute("id") ~= nil then
                self.idmap[element:get_attribute("id")] = element
            end

            if current_parent ~= nil then
                current_parent:append_child(element)
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

function DOM.Document:get_element_by_id(id)
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
    local self = setmetatable({
        parent = nil;
        name = name;
        attributes = attributes;
        children = children;
    }, DOM.Element)

    -- set ourselves as the parent of our children
    if children ~= nil then
        for i = 1, #children do
            children[i].parent = self
        end
    end

    return self
end

function DOM.Element:insert_child(i, element)
    if self.children == nil then
        self.children = {}
    end

    table.insert(self.children, i, element)
end

function DOM.Element:remove_child(element)
    if self.children == nil then
        return
    end

    for i = 1, #(self.children) do
        local child = self.children[i]

        if child == element then
            table.remove(self.children, i)
            child.parent = nil
            return
        end
    end
end

function DOM.Element:append_child(element)
    if self.children == nil then
        self.children = {}
    end

    if element.parent ~= nil then
        element.parent:remove_child(element)
    end

    table.insert(self.children, element)
    element.parent = self
end

function DOM.Element:get_attribute(name, inherit, default)
    local value = nil
    local this = self

    repeat
        if this.attributes ~= nil then
            value = this.attributes[name]
        end

        this = this.parent

        -- Repeat if the attribute is to be inherited
    until not (inherit and value == nil and this ~= nil)

    if value == nil then
        return default

    else
        return value
    end
end

function DOM.Element:set_attribute(name, value)
    if self.attributes == nil then
        self.attributes = {}
    end

    self.attributes[name] = value
end

function DOM.Element:clone()
    local attributes_copy = nil
    local children_copy = nil

    -- clone attributes
    if self.attributes ~= nil then
        attributes_copy = {}

        for k, v in pairs(self.attributes) do
            attributes_copy[k] = v
        end
    end

    -- clone children
    if self.children ~= nil then
        children_copy = {}

        -- recursively clone children
        for _, child in ipairs(self.children) do
            table.insert(children_copy, child:clone())
        end
    end

    return DOM.Element(self.name, attributes_copy, children_copy)
end

function DOM.Element:__tostring()
    return element_tostring(self)
end

return DOM

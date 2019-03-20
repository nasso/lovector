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

local function _element(name, attributes, children)
    return {
        parent = nil;
        name = name;
        attributes = attributes;
        children = children;
    }
end

local function xmlparse(source)
    local xml = {
        root = _element("document", nil, {})
    }

    local current_parent = xml.root

    for tag, closes, name, attributes, empty in source:gmatch("(<(/?)([:A-Z_a-z][:A-Z_a-z0-9%-%.]*)(.-)(/?)>)") do
        closes = closes == "/"
        empty = empty == "/"

        if not closes then
            local element = _element(name, _attributes(attributes))
            element.parent = current_parent

            table.insert(current_parent.children, element)

            if not empty then
                element.children = {}
                current_parent = element
            end
        else
            current_parent = current_parent.parent
        end
    end

    return xml
end

return xmlparse

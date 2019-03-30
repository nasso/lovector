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
local Graphics = require(cwd .. "graphics")
local DOM = require(cwd .. "svg.dom")
local common = require(cwd .. "svg.common")

local DEFAULT_OPTIONS = {
    ["debug"] = false;
    ["path_debug"] = false;
    ["stroke_debug"] = false;
}

--- Creates a Graphics from the given SVG file
local function SVG(source, options)
    -- Arg check
    assert(type(source) == "string", "\"source\" should be a string, but is " .. type(source))

    options = options or {}

    for k, v in pairs(DEFAULT_OPTIONS) do
        if options[k] == nil then
            options[k] = v
        end
    end

    -- if the source argument is a path, load it
    if not source:match("<?xml") then
        local contents, err = love.filesystem.read(source)

        if contents == nil then
            error(err)
        end

        source = contents
    end

    local svg = {
        document = DOM.Document(source);
        width = 0;
        height = 0;
        graphics = Graphics(options);
    }

    common.gen(svg, svg.document.root, options)

    return svg.graphics
end

return SVG

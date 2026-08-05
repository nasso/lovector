--[[
MIT License

Copyright (c) nasso.dev

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

local ArgsReader = {}
ArgsReader.__index = ArgsReader
setmetatable(ArgsReader, {
    -- constructor
    __call = function(_, str)
        local self = setmetatable({}, ArgsReader)
        self:reset(str)
        return self
    end
})

function ArgsReader:reset(str)
    self.str = str or ""
    self.pos = 1
end

function ArgsReader:eos()
    return self.pos >= #self.str
end

--- consumes whitespace and an optional comma
--- @return boolean c whether a comma was consumed
function ArgsReader:comma_wsp()
    -- (wsp+ comma? wsp*) | (comma wsp*)
    local i, j, c = self.str:find("^%s+(,?)%s*", self.pos)
    if not i then i, j, c = self.str:find("^(,)%s*", self.pos) end
    if not i then return false end
    self.pos = j + 1
    return c == ","
end

function ArgsReader:num()
    -- integer or floating-point number
    local num = self.str:match("^[%-%+]?%.%d+", self.pos)  -- +.1234
    if not num then
        num = self.str:match("^[%-%+]?%d+%.%d*", self.pos) -- +123. -12.34
    end
    if not num then
        num = self.str:match("^[%-%+]?%d+", self.pos) -- +123
    end
    if not num then return end
    self.pos = self.pos + #num

    -- exponent (optional)
    local exp = self.str:match("^[eE][%-%+]?%d+", self.pos)
    if exp then
        self.pos = self.pos + #exp
        num = num .. exp
    end
    return tonumber(num, 10)
end

function ArgsReader:coords()
    local x = self:num()
    if not x then return end
    self:comma_wsp()
    local y = self:num()
    if not y then return end
    return x, y
end

function ArgsReader:flag()
    local flag = self.str:match("[01]", self.pos)
    if not flag then return end
    self.pos = self.pos + 1
    return flag == "1"
end

local renderer = {}

function renderer:empty(svg, options)
    local pathdef = common.get_attr(self, "d")

    -- in case a genius put a <path> without a path
    if pathdef == nil then
        return ""
    end

    -- output
    local path = PathBuilder(options)

    local prev_ctrlx = 0
    local prev_ctrly = 0

    -- iterate through all dem commands
    local reader = ArgsReader()
    for op, strargs in string.gmatch(pathdef, "%s*([MmLlHhVvCcSsQqTtAaZz])%s*([^MmLlHhVvCcSsQqTtAaZz]*)%s*") do
        reader:reset(strargs)

        if op == "M" or op == "m" then
            -- move to
            repeat
                local x, y = reader:coords()
                if not x then break end

                if op == "m" then
                    local cpx, cpy = path:last_point()
                    x = cpx + x
                    y = cpy + y
                end

                path:move_to(x, y)
            until not reader:comma_wsp() and reader:eos()
        elseif op == "L" or op == "l" then
            -- line to
            repeat
                local x, y = reader:coords()
                if not x then break end

                if op == "l" then
                    local cpx, cpy = path:last_point()
                    x = cpx + x
                    y = cpy + y
                end

                path:line_to(x, y)
            until not reader:comma_wsp() and reader:eos()
        elseif op == "H" or op == "h" then
            -- line to (horizontal)
            repeat
                local cpx, cpy = path:last_point()

                local x = reader:num()
                if not x then break end

                if op == "h" then
                    x = cpx + x
                end

                path:line_to(x, cpy)
            until not reader:comma_wsp() and reader:eos()
        elseif op == "V" or op == "v" then
            -- line to (vertical)
            repeat
                local cpx, cpy = path:last_point()

                local y = reader:num()
                if not y then break end

                if op == "v" then
                    y = cpy + y
                end

                path:line_to(cpx, y)
            until not reader:comma_wsp() and reader:eos()
        elseif op == "C" or op == "c" then
            -- cubic bezier curve
            repeat
                local x1, y1 = reader:coords()
                if not x1 then break end
                reader:comma_wsp()
                local x2, y2 = reader:coords()
                if not x2 then break end
                reader:comma_wsp()
                local x, y = reader:coords()
                if not x then break end

                if op == "c" then
                    local cpx, cpy = path:last_point()
                    x1 = cpx + x1
                    y1 = cpy + y1
                    x2 = cpx + x2
                    y2 = cpy + y2
                    x = cpx + x
                    y = cpy + y
                end

                path:bezier_curve_to(x1, y1, x2, y2, x, y)

                -- remember the end control point for the next command
                prev_ctrlx = x2
                prev_ctrly = y2
            until not reader:comma_wsp() and reader:eos()
        elseif op == "S" or op == "s" then
            -- smooth cubic Bézier curve
            repeat
                local cpx, cpy = path:last_point()

                local x2, y2 = reader:coords()
                if not x2 then break end
                reader:comma_wsp()
                local x, y = reader:coords()
                if not x then break end

                if op == "s" then
                    x2 = cpx + x2
                    y2 = cpy + y2
                    x = cpx + x
                    y = cpy + y
                end

                -- calculate the start control point
                local x1 = cpx + cpx - prev_ctrlx
                local y1 = cpy + cpy - prev_ctrly

                path:bezier_curve_to(x1, y1, x2, y2, x, y)

                -- remember the end control point for the next command
                prev_ctrlx = x2
                prev_ctrly = y2
            until not reader:comma_wsp() and reader:eos()
        elseif op == "Q" or op == "q" then
            -- quadratic Bézier curve
            repeat
                local x1, y1 = reader:coords()
                if not x1 then break end
                reader:comma_wsp()
                local x, y = reader:coords()
                if not x then break end

                if op == "q" then
                    local cpx, cpy = path:last_point()
                    x1 = cpx + x1
                    y1 = cpy + y1
                    x = cpx + x
                    y = cpy + y
                end

                path:quadratic_curve_to(x1, y1, x, y)

                -- remember the end control point for the next command
                prev_ctrlx = x1
                prev_ctrly = y1
            until not reader:comma_wsp() and reader:eos()
        elseif op == "T" or op == "t" then
            -- smooth quadratic Bézier curve
            repeat
                local cpx, cpy = path:last_point()

                local x, y = reader:coords()
                if not x then break end

                if op == "t" then
                    x = cpx + x
                    y = cpy + y
                end

                -- calculate the control point
                local x1 = cpx + cpx - prev_ctrlx
                local y1 = cpy + cpy - prev_ctrly

                path:quadratic_curve_to(x1, y1, x, y)

                -- remember the end control point for the next command
                prev_ctrlx = x1
                prev_ctrly = y1
            until not reader:comma_wsp() and reader:eos()
        elseif op == "A" or op == "a" then
            -- arc to
            repeat
                local rx, ry = reader:coords()
                if not rx then break end
                reader:comma_wsp()
                local angle = reader:num()
                if not angle then break end
                reader:comma_wsp()
                local large_arc = reader:flag()
                if large_arc == nil then break end
                reader:comma_wsp()
                local sweep = reader:flag()
                if sweep == nil then break end
                reader:comma_wsp()
                local x, y = reader:coords()
                if not x then break end

                if op == "a" then
                    local cpx, cpy = path:last_point()
                    x = cpx + x
                    y = cpy + y
                end

                path:elliptical_arc_to(rx, ry, angle, large_arc, sweep, x, y)
            until not reader:comma_wsp() and reader:eos()
        elseif op == "Z" or op == "z" then
            -- close shape (relative and absolute are the same)
            path:close_path()
        end

        -- if the command wasn't a curve command, set prev_ctrlx and prev_ctrly to cpx and cpy
        if not string.match(op, "[CcSsQqTt]") then
            prev_ctrlx, prev_ctrly = path:last_point()
        end
    end

    -- render everything!
    svg.graphics:draw_path(path)
end

return renderer

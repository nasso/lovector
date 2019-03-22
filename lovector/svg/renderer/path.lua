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

function renderer:empty(svg, options)
    local pathdef = common.get_attr(self, "d")

    -- in case a genius put a <path> without a path
    if pathdef == nil then
        return ""
    end

    -- output
    local result = ""

    local ipx = 0
    local ipy = 0
    local cpx = 0
    local cpy = 0
    local prev_ctrlx = 0
    local prev_ctrly = 0
    local vertices = {}

    -- iterate through all dem commands
    for op, strargs in string.gmatch(pathdef, "%s*([MmLlHhVvCcSsQqTtAaZz])%s*([^MmLlHhVvCcSsQqTtAaZz]*)%s*") do
        local args = {}

        -- parse command arguments
        if strargs ~= nil and #strargs > 0 then
            for arg in string.gmatch(strargs, "%-?[^%s,%-]+") do
               table.insert(args, 1, tonumber(arg,10))
            end
        end

        -- move to
        if op == "M" then
            result = result .. common.gensubpath(svg, self, vertices, false, options)
            vertices = {}

            ipx = table.remove(args)
            ipy = table.remove(args)
            cpx = ipx
            cpy = ipy

            table.insert(vertices, cpx)
            table.insert(vertices, cpy)

            while #args >= 2 do
                cpx = table.remove(args)
                cpy = table.remove(args)

                table.insert(vertices, cpx)
                table.insert(vertices, cpy)
            end

        -- move to (relative)
        elseif op == "m" then
            result = result .. common.gensubpath(svg, self, vertices, false, options)
            vertices = {}

            ipx = cpx + table.remove(args)
            ipy = cpy + table.remove(args)
            cpx = ipx
            cpy = ipy

            table.insert(vertices, cpx)
            table.insert(vertices, cpy)

            while #args >= 2 do
                cpx = cpx + table.remove(args)
                cpy = cpy + table.remove(args)

                table.insert(vertices, cpx)
                table.insert(vertices, cpy)
            end

        -- line to
        elseif op == "L" then
            while #args >= 2 do
                cpx = table.remove(args)
                cpy = table.remove(args)

                table.insert(vertices, cpx)
                table.insert(vertices, cpy)
            end

        -- line to (relative)
        elseif op == "l" then
            while #args >= 2 do
                cpx = cpx + table.remove(args)
                cpy = cpy + table.remove(args)

                table.insert(vertices, cpx)
                table.insert(vertices, cpy)
            end

        -- line to (horizontal)
        elseif op == "H" then
            while #args >= 1 do
                cpx = table.remove(args)

                table.insert(vertices, cpx)
                table.insert(vertices, cpy)
            end

        -- line to (horizontal, relative)
        elseif op == "h" then
            while #args >= 1 do
                cpx = cpx + table.remove(args)

                table.insert(vertices, cpx)
                table.insert(vertices, cpy)
            end

        -- line to (vertical)
        elseif op == "V" then
            while #args >= 1 do
                cpy = table.remove(args)

                table.insert(vertices, cpx)
                table.insert(vertices, cpy)
            end

        -- line to (vertical, relative)
        elseif op == "v" then
            while #args >= 1 do
                cpy = cpy + table.remove(args)

                table.insert(vertices, cpx)
                table.insert(vertices, cpy)
            end

        -- cubic bezier curve
        elseif op == "C" then
            while #args >= 6 do
                local x1 = table.remove(args)
                local y1 = table.remove(args)
                local x2 = table.remove(args)
                local y2 = table.remove(args)
                local x = table.remove(args)
                local y = table.remove(args)

                -- generate vertices
                local curve = love.math.newBezierCurve(cpx, cpy, x, y)
                curve:insertControlPoint(x1, y1)
                curve:insertControlPoint(x2, y2)

                for _, v in ipairs(curve:render(options["bezier_depth"])) do
                    table.insert(vertices, v)
                end

                -- release object
                curve:release()

                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x2
                prev_ctrly = y2
            end

        -- cubic bezier curve (relative)
        elseif op == "c" then
            while #args >= 6 do
                local x1 = cpx + table.remove(args)
                local y1 = cpy + table.remove(args)
                local x2 = cpx + table.remove(args)
                local y2 = cpy + table.remove(args)
                local x = cpx + table.remove(args)
                local y = cpy + table.remove(args)

                -- generate vertices
                local curve = love.math.newBezierCurve(cpx, cpy, x, y)
                curve:insertControlPoint(x1, y1)
                curve:insertControlPoint(x2, y2)

                for _, v in ipairs(curve:render(options["bezier_depth"])) do
                    table.insert(vertices, v)
                end

                -- release object
                curve:release()

                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x2
                prev_ctrly = y2
            end

        -- smooth cubic Bézier curve
        elseif op == "S" then
            while #args >= 4 do
                local x2 = table.remove(args)
                local y2 = table.remove(args)
                local x = table.remove(args)
                local y = table.remove(args)

                -- calculate the start control point
                local x1 = cpx + cpx - prev_ctrlx
                local y1 = cpy + cpy - prev_ctrly

                -- generate vertices
                local curve = love.math.newBezierCurve(cpx, cpy, x, y)
                curve:insertControlPoint(x1, y1)
                curve:insertControlPoint(x2, y2)

                for _, v in ipairs(curve:render(options["bezier_depth"])) do
                    table.insert(vertices, v)
                end

                -- release object
                curve:release()

                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x2
                prev_ctrly = y2
            end

        -- smooth cubic Bézier curve (relative)
        elseif op == "s" then
            while #args >= 4 do
                local x2 = cpx + table.remove(args)
                local y2 = cpy + table.remove(args)
                local x = cpx + table.remove(args)
                local y = cpy + table.remove(args)

                -- calculate the start control point
                local x1 = cpx + cpx - prev_ctrlx
                local y1 = cpy + cpy - prev_ctrly

                -- generate vertices
                local curve = love.math.newBezierCurve(cpx, cpy, x, y)
                curve:insertControlPoint(x1, y1)
                curve:insertControlPoint(x2, y2)

                for _, v in ipairs(curve:render(options["bezier_depth"])) do
                    table.insert(vertices, v)
                end

                -- release object
                curve:release()

                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x2
                prev_ctrly = y2
            end

        -- quadratic Bézier curve
        elseif op == "Q" then
            while #args >= 4 do
                local x1 = table.remove(args)
                local y1 = table.remove(args)
                local x = table.remove(args)
                local y = table.remove(args)

                -- generate vertices
                local curve = love.math.newBezierCurve(cpx, cpy, x, y)
                curve:insertControlPoint(x1, y1)

                for _, v in ipairs(curve:render(options["bezier_depth"])) do
                    table.insert(vertices, v)
                end

                -- release object
                curve:release()

                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x1
                prev_ctrly = y1
            end

        -- quadratic Bézier curve (relative)
        elseif op == "q" then
            while #args >= 4 do
                local x1 = cpx + table.remove(args)
                local y1 = cpy + table.remove(args)
                local x = cpx + table.remove(args)
                local y = cpy + table.remove(args)

                -- generate vertices
                local curve = love.math.newBezierCurve(cpx, cpy, x, y)
                curve:insertControlPoint(x1, y1)

                for _, v in ipairs(curve:render(options["bezier_depth"])) do
                    table.insert(vertices, v)
                end

                -- release object
                curve:release()

                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x1
                prev_ctrly = y1
            end

        -- smooth quadratic Bézier curve
        elseif op == "T" then
            while #args >= 2 do
                local x = table.remove(args)
                local y = table.remove(args)

                -- calculate the control point
                local x1 = cpx + cpx - prev_ctrlx
                local y1 = cpy + cpy - prev_ctrly

                -- generate vertices
                local curve = love.math.newBezierCurve(cpx, cpy, x, y)
                curve:insertControlPoint(x1, y1)

                for _, v in ipairs(curve:render(options["bezier_depth"])) do
                    table.insert(vertices, v)
                end

                -- release object
                curve:release()

                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x1
                prev_ctrly = y1
            end

        -- smooth quadratic Bézier curve (relative)
        elseif op == "t" then
            while #args >= 2 do
                local x = cpx + table.remove(args)
                local y = cpy + table.remove(args)

                -- calculate the control point
                local x1 = cpx + cpx - prev_ctrlx
                local y1 = cpy + cpy - prev_ctrly

                -- generate vertices
                local curve = love.math.newBezierCurve(cpx, cpy, x, y)
                curve:insertControlPoint(x1, y1)

                for _, v in ipairs(curve:render(options["bezier_depth"])) do
                    table.insert(vertices, v)
                end

                -- release object
                curve:release()

                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x1
                prev_ctrly = y1
            end

        -- arc to
        elseif op == "A" then
            while #args >= 7 do
                local rx = table.remove(args)
                local ry = table.remove(args)
                local angle = table.remove(args)
                local large_arc_flag = table.remove(args)
                local sweep_flag = table.remove(args)
                local x = table.remove(args)
                local y = table.remove(args)

                common.buildarc(cpx, cpy, rx, ry, angle, large_arc_flag, sweep_flag, x, y, options["arc_segments"], vertices)

                cpx = x
                cpy = y

                table.insert(vertices, cpx)
                table.insert(vertices, cpy)
            end

        -- arc to (relative)
        elseif op == "a" then
            while #args >= 7 do
                local rx = table.remove(args)
                local ry = table.remove(args)
                local angle = table.remove(args)
                local large_arc_flag = table.remove(args)
                local sweep_flag = table.remove(args)
                local x = cpx + table.remove(args)
                local y = cpy + table.remove(args)

                common.buildarc(cpx, cpy, rx, ry, angle, large_arc_flag, sweep_flag, x, y, options["arc_segments"], vertices)

                cpx = x
                cpy = y
            end

        -- close shape (relative and absolute are the same)
        elseif op == "Z" or op == "z" then
            result = result .. common.gensubpath(svg, self, vertices, true, options)

            cpx = ipx
            cpy = ipy

            table.insert(vertices, cpx)
            table.insert(vertices, cpy)
        end

        -- if the command wasn't a curve command, set prev_ctrlx and prev_ctrly to cpx and cpy
        if not string.match(op, "[CcSsQqTt]") then
            prev_ctrlx = cpx
            prev_ctrly = cpy
        end
    end

    -- one last time~!
    result = result .. common.gensubpath(svg, self, vertices, false, options)

    if common.get_attr(self, "transform") ~= nil then
        result =
            "love.graphics.push()\n" ..
            common.transformparse(svg, common.get_attr(self, "transform")) ..
            result ..
            "love.graphics.pop()\n"
    end

    return result
end

return renderer

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
local colorparse = require(cwd .. "colorparse")

local INHERIT = {
    ["x"] = true;
    ["y"] = true;
    ["color"] = true;
    ["fill"] = true;
    ["fill-opacity"] = true;
    ["fill-rule"] = true;
    ["opacity"] = true;
    ["stroke"] = true;
    ["stroke-opacity"] = true;
    ["stroke-width"] = true;
}

local ELEMENTS = {
    ["g"] = "g";
    ["path"] = "path";
    ["rect"] = "rect";
    ["svg"] = "svg";
}

local common = {}

function common.transformparse(svg, transform)
    local result = ""

    -- parse every command
    for cmd, strargs in string.gmatch(transform, "%s*(.-)%s*%((.-)%)") do
        local args = {}

        -- parse command arguments
        if strargs ~= nil and #strargs > 0 then
            for arg in string.gmatch(strargs, "%-?[^%s,%-]+") do
               table.insert(args, 1, tonumber(arg, 10))
            end
        end

        -- translate
        if cmd == "translate" then
            local x = table.remove(args)
            local y = table.remove(args) or 0

            result = result .. "love.graphics.translate(" .. x .. ", " .. y .. ")\n"

        -- rotate
        elseif cmd == "rotate" then
            local a = table.remove(args)
            local x = table.remove(args) or 0
            local y = table.remove(args) or 0

            if x ~= 0 and y ~= 0 then
                result = result .. "love.graphics.translate(" .. x .. ", " .. y .. ")\n"
            end

            result = result .. "love.graphics.rotate(" .. math.rad(a) .. ")\n"

            if x ~= 0 and y ~= 0 then
                result = result .. "love.graphics.translate(" .. (-x) .. ", " .. (-y) .. ")\n"
            end

        -- scale
        elseif cmd == "scale" then
            local x = table.remove(args)
            local y = table.remove(args)

            if y == nil then
                y = x
            end

            result = result .. "love.graphics.scale(" .. x .. ", " .. y .. ")\n"

        -- matrix
        elseif cmd == "matrix" then
            local a = table.remove(args)
            local b = table.remove(args)
            local c = table.remove(args)
            local d = table.remove(args)
            local e = table.remove(args)
            local f = table.remove(args)

            local matrix = love.math.newTransform()
            matrix:setMatrix(
                a, c, e, 0,
                b, d, f, 0,
                0, 0, 1, 0,
                0, 0, 0, 1
            )
            table.insert(svg.extdata, matrix)

            result = result .. "love.graphics.applyTransform(extdata[" .. (#svg.extdata) .. "])\n"

        elseif cmd == "skewX" then
            local a = table.remove(args)

            result = result .. "love.graphics.shear(" .. math.rad(a) .. ", 0)\n"

        elseif cmd == "skewY" then
            local a = table.remove(args)

            result = result .. "love.graphics.shear(0, " .. math.rad(a) .. ")\n"

        else
            -- let em know what's missing!!!
            print("Unimplemented transform command: " .. cmd .. "!")
            os.exit()
        end
    end

    return result
end

function common.vecangle(ux, uy, vx, vy)
    local cross = ux * vy - uy * vx
    local dot = ux * vx + uy * vy

    -- clamp it to avoid floating-point arithmetics errors
    dot = math.min(1, math.max(-1, dot))

    local result = math.deg(math.acos(dot))

    if cross >= 0 then
        return result
    else
        return -result
    end
end

function common.endpoint2center(x1, y1, x2, y2, fa, fs, rx, ry, phi)
    -- Pre-compute some stuff
    local rad_phi = math.rad(phi)
    local cos_phi = math.cos(rad_phi)
    local sin_phi = math.sin(rad_phi)

    -- Step 1: Compute (x1_, y1_)
    local x1_ = cos_phi * (x1-x2)/2 + sin_phi * (y1-y2)/2
    local y1_ = -sin_phi * (x1-x2)/2 + cos_phi * (y1-y2)/2

    -- Step 2: Compute (cx_, cy_)
    local f = math.sqrt(
        math.max(rx*rx * ry*ry - rx*rx * y1_*y1_ - ry*ry * x1_*x1_, 0) -- rounding errors safety
        /
        (rx*rx * y1_*y1_ + ry*ry * x1_*x1_)
    )

    if fa == fs then
        f = -f
    end

    local cx_ =  f * rx * y1_ / ry
    local cy_ = -f * ry * x1_ / rx

    -- Step 3: Compute (cx, cy) from (cx_, cy_)
    local cx = cos_phi * cx_ - sin_phi * cy_ + (x1+x2)/2
    local cy = sin_phi * cx_ + cos_phi * cy_ + (y1+y2)/2

    -- Step 4: Compute theta1 and dtheta
    local vx = (x1_-cx_)/rx
    local vy = (y1_-cy_)/ry

    local theta1 = common.vecangle(1, 0, vx, vy)
    local dtheta = common.vecangle(vx, vy, (-x1_-cx_)/rx, (-y1_-cy_)/ry) % 360

    if not fs and dtheta > 0 then
        dtheta = dtheta - 360
    elseif fs and dtheta < 0 then
        dtheta = dtheta + 360
    end

    return cx, cy, theta1, dtheta
end

function common.buildarc(sx, sy, rx, ry, phi, fa, fs, ex, ey, segments, vertices)
    -- Argument checking
    if segments == nil then
        segments = 10
    end

    segments = math.max(segments, 1)

    if vertices == nil then
        vertices = {}
    end

    -- Out-of-range checks

    -- - That's stupid
    if sx == ex and sy == ey then
        return vertices
    end

    -- - That's just a line!
    if rx == 0 or ry == 0 then
        table.insert(vertices, ex)
        table.insert(vertices, ey)
    end

    -- - Negatives are a lie!
    rx = math.abs(rx)
    ry = math.abs(ry)

    -- - When your radii are too small
    local rad_phi = math.rad(phi)
    local cos_phi = math.cos(rad_phi)
    local sin_phi = math.sin(rad_phi)

    local x1_ = cos_phi * (sx-ex)/2 + sin_phi * (sy-ey)/2
    local y1_ = -sin_phi * (sx-ex)/2 + cos_phi * (sy-ey)/2

    local lambda = x1_*x1_/(rx*rx) + y1_*y1_/(ry*ry)

    if lambda > 1 then
        local sqrt_lambda = math.sqrt(lambda)

        rx = sqrt_lambda * rx
        ry = sqrt_lambda * ry
    end

    -- - When you go too far:
    phi = phi % 360

    -- - Bang bang, you're a boolean
    fa = fa ~= 0
    fs = fs ~= 0

    local cx, cy, theta1, dtheta = common.endpoint2center(sx, sy, ex, ey, fa, fs, rx, ry, phi)

    for i = 1, segments do
        local theta = math.rad(theta1 + dtheta * (i / segments))
        local cos_theta = math.cos(theta)
        local sin_theta = math.sin(theta)

        table.insert(vertices, cos_phi * rx * cos_theta - sin_phi * ry * sin_theta + cx)
        table.insert(vertices, sin_phi * rx * cos_theta + cos_phi * ry * sin_theta + cy)
    end

    return vertices
end

function common.get_attr(element, attrname, default)
    return element:getAttribute(attrname, INHERIT[attrname], default)
end

function common.gensubpath(svg, element, vertices, closed, options)
    local vertexcount = #vertices

    if vertexcount < 4 then
        return ""
    end

    table.insert((svg.extdata), vertices)
    local bufferid = #svg.extdata

    -- attributes!

    --  colors (red/green/blue)
    local f_red, f_green, f_blue, f_alpha = colorparse(common.get_attr(element, "fill", "black"))
    local s_red, s_green, s_blue, s_alpha = colorparse(common.get_attr(element, "stroke", "none"))

    --  opacity
    local opacity = tonumber(common.get_attr(element, "opacity", "1"), 10)

    --  fill-opacity
    local f_opacity = tonumber(common.get_attr(element, "fill-opacity", "1"), 10)

    --  stroke-opacity
    local s_opacity = tonumber(common.get_attr(element, "stroke-opacity", "1"), 10)

    -- stroke
    local linewidth = tonumber(common.get_attr(element, "stroke-width", "1"), 10)

    -- check if we're even going to draw anything
    if f_red == nil and s_red == nil then
        return ""
    end

    local result = ""

    -- fill
    if f_red ~= nil and vertexcount >= 6 then
        if options.use_love_fill == true then
            result = result ..
                "love.graphics.setColor(" .. f_red .. ", " .. f_green .. ", " .. f_blue .. ", " .. (f_alpha * f_opacity * opacity) .. ")\n" ..
                "love.graphics.polygon(\"fill\", extdata[" .. bufferid .. "])"
        else
            local minx, miny, maxx, maxy = vertices[1], vertices[2], vertices[1], vertices[2]

            for i = 3, vertexcount, 2 do
                minx = math.min(minx, vertices[i])
                miny = math.min(miny, vertices[i+1])
                maxx = math.max(maxx, vertices[i])
                maxy = math.max(maxy, vertices[i+1])
            end

            local stencil_fn =
                "local extdata = ...\n" ..
                "return function() love.graphics.polygon(\"fill\", extdata[" .. bufferid .. "]) end\n"

            -- insert the stencil rendering function
            table.insert(svg.extdata, assert(loadstring(stencil_fn))(svg.extdata))

            result = result ..
                "love.graphics.stencil(extdata[" .. (#svg.extdata) .. "], \"invert\")\n" ..
                "love.graphics.setStencilTest(\"notequal\", 0)\n" ..
                "love.graphics.setColor(" .. f_red .. ", " .. f_green .. ", " .. f_blue .. ", " .. (f_alpha * f_opacity * opacity) .. ")\n" ..
                "love.graphics.rectangle(\"fill\", " .. minx .. ", " .. miny .. ", " .. (maxx-minx) .. ", " .. (maxy-miny) .. ")" ..
                "love.graphics.setStencilTest()\n"
        end
    end

    -- stroke
    if s_red ~= nil and vertexcount >= 4 then
        result = result .. "love.graphics.setColor(" .. s_red .. ", " .. s_green .. ", " .. s_blue .. ", " .. (s_alpha * s_opacity * opacity) .. ")\n"
        result = result .. "love.graphics.setLineWidth(" .. linewidth .. ")\n"

        if closed == true then
            result = result .. "love.graphics.polygon(\"line\", extdata[" .. bufferid .. "])\n"
        else
            result = result .. "love.graphics.line(extdata[" .. bufferid .. "])\n"
        end
    end

    return result
end

function common.gen(svg, element, options)
    local renderer = ELEMENTS[element.name]

    -- No renderer for this element
    if renderer == nil then
        if options.debug then
            print("No renderer for <" .. element.name .. ">")
        end

        return ""
    end

    -- Load the renderer
    renderer = require(cwd .. "svg.renderer." .. ELEMENTS[element.name])

    -- Empty elements
    if element.children == nil then
        if renderer.empty == nil then
            return ""
        end

        return renderer.empty(element, svg, options)
    end

    -- Containers
    local result = nil
    local state = nil

    if renderer.open ~= nil then
        result, state = renderer.open(element, svg, options)
    else
        result = ""
    end

    for i = 1, #(element.children) do
        result = result .. common.gen(svg, element.children[i], options)
    end


    return result .. renderer.close(element, state, svg, options)
end

return common

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

function common.get_attr(element, attrname, default)
    return element:getAttribute(attrname, INHERIT[attrname], default)
end

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

function common.remove_doubles(vertices, epsilon)
    if #vertices < 2 or #vertices % 2 ~= 0 then
        error("the vertex array must have length greater or equal than 2, and be even")
        return nil
    end

    -- default epsilon to 0
    epsilon = epsilon or 0

    -- where we're going to store vertices
    local clean_vertices = {}

    -- add at least 1
    table.insert(clean_vertices, vertices[1])
    table.insert(clean_vertices, vertices[2])

    -- add all the others
    for i = 3, #vertices, 2 do
        if
            math.abs(vertices[i] - vertices[i - 2]) > epsilon or
            math.abs(vertices[i + 1] - vertices[i - 1]) > epsilon
        then
            table.insert(clean_vertices, vertices[i])
            table.insert(clean_vertices, vertices[i + 1])
        end
    end

    -- return the array
    return clean_vertices
end

function common.gensubpath(svg, element, vertices, closed, options)
    -- not enough vertices
    if #vertices < 4 then
        return ""
    end

    -- remove doubles
    vertices = common.remove_doubles(vertices, 1 / 1000)

    -- check vertice count again because it might have changed
    if #vertices < 4 then
        return ""
    end

    -- add the new, clean vertex buffer to the data
    table.insert(svg.extdata, vertices)

    local bufferid = #svg.extdata

    -- attributes!

    --  colors (red/green/blue)
    local f_red, f_green, f_blue, f_alpha = colorparse(common.get_attr(element, "fill", "black"))
    local s_red, s_green, s_blue, s_alpha = colorparse(common.get_attr(element, "stroke", "none"))

    -- opacity
    local opacity = tonumber(common.get_attr(element, "opacity", "1"), 10)
    local f_opacity = tonumber(common.get_attr(element, "fill-opacity", "1"), 10)
    local s_opacity = tonumber(common.get_attr(element, "stroke-opacity", "1"), 10)

    -- line width
    local linewidth = tonumber(common.get_attr(element, "stroke-width", "1"), 10)

    -- check if we're even going to draw anything
    if f_red == nil and s_red == nil then
        return ""
    end

    local result = ""

    -- fill
    if f_red ~= nil and #vertices >= 6 then
        if options.use_love_fill == true then
            result = result ..
                "love.graphics.setColor(" .. f_red .. ", " .. f_green .. ", " .. f_blue .. ", " .. (f_alpha * f_opacity * opacity) .. ")\n" ..
                "love.graphics.polygon(\"fill\", extdata[" .. bufferid .. "])"
        else
            local minx, miny, maxx, maxy = vertices[1], vertices[2], vertices[1], vertices[2]

            for i = 3, #vertices, 2 do
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
    if s_red ~= nil and #vertices >= 4 then
        result = result .. "love.graphics.setColor(" .. s_red .. ", " .. s_green .. ", " .. s_blue .. ", " .. (s_alpha * s_opacity * opacity) .. ")\n"
        result = result .. "love.graphics.setLineWidth(" .. linewidth .. ")\n"

        if closed == true then
            result = result .. "love.graphics.polygon(\"line\", extdata[" .. bufferid .. "])\n"
        else
            result = result .. "love.graphics.line(extdata[" .. bufferid .. "])\n"
        end

        if options["stroke_debug"] then
            local r,g,b = common.HSL(math.random(), 1, .5)
            result = result .. "love.graphics.setColor(" .. r .. ", " .. g .. ", " .. b .. ",.5)\n"
            result = result .. "love.graphics.setPointSize(5)\n"
            result = result .. "love.graphics.points(extdata[" .. bufferid .. "])\n"
        end
    end

    return result
end

function common.HSL(h, s, l, a)
    if s<=0 then return l,l,l,a end
    h, s, l = h*6, s, l
    local c = (1-math.abs(2*l-1))*s
    local x = (1-math.abs(h%2-1))*c
    local m,r,g,b = (l-.5*c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end return (r+m),(g+m),(b+m),a
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

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
local stroke = require(cwd .. "stroke")
local ELEMENTS = require(cwd .. "svg.renderer")

local COLOR_NAMES = {
    ["aliceblue"] = {240,248,255,255};
    ["antiquewhite"] = {250,235,215,255};
    ["aqua"] = {0,255,255,255};
    ["aquamarine"] = {127,255,212,255};
    ["azure"] = {240,255,255,255};
    ["beige"] = {245,245,220,255};
    ["bisque"] = {255,228,196,255};
    ["black"] = {0,0,0,255};
    ["blanchedalmond"] = {255,235,205,255};
    ["blue"] = {0,0,255,255};
    ["blueviolet"] = {138,43,226,255};
    ["brown"] = {165,42,42,255};
    ["burlywood"] = {222,184,135,255};
    ["cadetblue"] = {95,158,160,255};
    ["chartreuse"] = {127,255,0,255};
    ["chocolate"] = {210,105,30,255};
    ["coral"] = {255,127,80,255};
    ["cornflowerblue"] = {100,149,237,255};
    ["cornsilk"] = {255,248,220,255};
    ["crimson"] = {220,20,60,255};
    ["cyan"] = {0,255,255,255};
    ["darkblue"] = {0,0,139,255};
    ["darkcyan"] = {0,139,139,255};
    ["darkgoldenrod"] = {184,134,11,255};
    ["darkgray"] = {169,169,169,255};
    ["darkgreen"] = {0,100,0,255};
    ["darkgrey"] = {169,169,169,255};
    ["darkkhaki"] = {189,183,107,255};
    ["darkmagenta"] = {139,0,139,255};
    ["darkolivegreen"] = {85,107,47,255};
    ["darkorange"] = {255,140,0,255};
    ["darkorchid"] = {153,50,204,255};
    ["darkred"] = {139,0,0,255};
    ["darksalmon"] = {233,150,122,255};
    ["darkseagreen"] = {143,188,143,255};
    ["darkslateblue"] = {72,61,139,255};
    ["darkslategray"] = {47,79,79,255};
    ["darkslategrey"] = {47,79,79,255};
    ["darkturquoise"] = {0,206,209,255};
    ["darkviolet"] = {148,0,211,255};
    ["deeppink"] = {255,20,147,255};
    ["deepskyblue"] = {0,191,255,255};
    ["dimgray"] = {105,105,105,255};
    ["dimgrey"] = {105,105,105,255};
    ["dodgerblue"] = {30,144,255,255};
    ["firebrick"] = {178,34,34,255};
    ["floralwhite"] = {255,250,240,255};
    ["forestgreen"] = {34,139,34,255};
    ["fuchsia"] = {255,0,255,255};
    ["gainsboro"] = {220,220,220,255};
    ["ghostwhite"] = {248,248,255,255};
    ["gold"] = {255,215,0,255};
    ["goldenrod"] = {218,165,32,255};
    ["gray"] = {128,128,128,255};
    ["green"] = {0,128,0,255};
    ["greenyellow"] = {173,255,47,255};
    ["grey"] = {128,128,128,255};
    ["honeydew"] = {240,255,240,255};
    ["hotpink"] = {255,105,180,255};
    ["indianred"] = {205,92,92,255};
    ["indigo"] = {75,0,130,255};
    ["ivory"] = {255,255,240,255};
    ["khaki"] = {240,230,140,255};
    ["lavender"] = {230,230,250,255};
    ["lavenderblush"] = {255,240,245,255};
    ["lawngreen"] = {124,252,0,255};
    ["lemonchiffon"] = {255,250,205,255};
    ["lightblue"] = {173,216,230,255};
    ["lightcoral"] = {240,128,128,255};
    ["lightcyan"] = {224,255,255,255};
    ["lightgoldenrodyellow"] = {250,250,210,255};
    ["lightgray"] = {211,211,211,255};
    ["lightgreen"] = {144,238,144,255};
    ["lightgrey"] = {211,211,211,255};
    ["lightpink"] = {255,182,193,255};
    ["lightsalmon"] = {255,160,122,255};
    ["lightseagreen"] = {32,178,170,255};
    ["lightskyblue"] = {135,206,250,255};
    ["lightslategray"] = {119,136,153,255};
    ["lightslategrey"] = {119,136,153,255};
    ["lightsteelblue"] = {176,196,222,255};
    ["lightyellow"] = {255,255,224,255};
    ["lime"] = {0,255,0,255};
    ["limegreen"] = {50,205,50,255};
    ["linen"] = {250,240,230,255};
    ["magenta"] = {255,0,255,255};
    ["maroon"] = {128,0,0,255};
    ["mediumaquamarine"] = {102,205,170,255};
    ["mediumblue"] = {0,0,205,255};
    ["mediumorchid"] = {186,85,211,255};
    ["mediumpurple"] = {147,112,219,255};
    ["mediumseagreen"] = {60,179,113,255};
    ["mediumslateblue"] = {123,104,238,255};
    ["mediumspringgreen"] = {0,250,154,255};
    ["mediumturquoise"] = {72,209,204,255};
    ["mediumvioletred"] = {199,21,133,255};
    ["midnightblue"] = {25,25,112,255};
    ["mintcream"] = {245,255,250,255};
    ["mistyrose"] = {255,228,225,255};
    ["moccasin"] = {255,228,181,255};
    ["navajowhite"] = {255,222,173,255};
    ["navy"] = {0,0,128,255};
    ["oldlace"] = {253,245,230,255};
    ["olive"] = {128,128,0,255};
    ["olivedrab"] = {107,142,35,255};
    ["orange"] = {255,165,0,255};
    ["orangered"] = {255,69,0,255};
    ["orchid"] = {218,112,214,255};
    ["palegoldenrod"] = {238,232,170,255};
    ["palegreen"] = {152,251,152,255};
    ["paleturquoise"] = {175,238,238,255};
    ["palevioletred"] = {219,112,147,255};
    ["papayawhip"] = {255,239,213,255};
    ["peachpuff"] = {255,218,185,255};
    ["peru"] = {205,133,63,255};
    ["pink"] = {255,192,203,255};
    ["plum"] = {221,160,221,255};
    ["powderblue"] = {176,224,230,255};
    ["purple"] = {128,0,128,255};
    ["red"] = {255,0,0,255};
    ["rosybrown"] = {188,143,143,255};
    ["royalblue"] = {65,105,225,255};
    ["saddlebrown"] = {139,69,19,255};
    ["salmon"] = {250,128,114,255};
    ["sandybrown"] = {244,164,96,255};
    ["seagreen"] = {46,139,87,255};
    ["seashell"] = {255,245,238,255};
    ["sienna"] = {160,82,45,255};
    ["silver"] = {192,192,192,255};
    ["skyblue"] = {135,206,235,255};
    ["slateblue"] = {106,90,205,255};
    ["slategray"] = {112,128,144,255};
    ["slategrey"] = {112,128,144,255};
    ["snow"] = {255,250,250,255};
    ["springgreen"] = {0,255,127,255};
    ["steelblue"] = {70,130,180,255};
    ["tan"] = {210,180,140,255};
    ["teal"] = {0,128,128,255};
    ["thistle"] = {216,191,216,255};
    ["tomato"] = {255,99,71,255};
    ["turquoise"] = {64,224,208,255};
    ["violet"] = {238,130,238,255};
    ["wheat"] = {245,222,179,255};
    ["white"] = {255,255,255,255};
    ["whitesmoke"] = {245,245,245,255};
    ["yellow"] = {255,255,0,255};
    ["yellowgreen"] = {154,205,50 ,255};
}

local INHERIT = {
    ["color"] = true;
    ["fill"] = true;
    ["fill-opacity"] = true;
    ["fill-rule"] = true;
    ["opacity"] = true;
    ["stroke"] = true;
    ["stroke-opacity"] = true;
    ["stroke-width"] = true;
}

local SHAPE_MESH_VERTEX_FORMAT = {
    { "VertexPosition", "float", 2 }
}

local common = {}

function common.hsla_to_rgba(h, s, l, a)
    if s <= 0 then
        return l, l, l, a
    end

    h, s, l = h * 6, s, l
    local c = (1 - math.abs(2 * l - 1)) * s
    local x = (1 - math.abs(h % 2 - 1)) * c
    local m, r, g, b = (l - 0.5 * c), 0, 0, 0

    if     h < 1 then r, g, b = c, x, 0
    elseif h < 2 then r, g, b = x, c, 0
    elseif h < 3 then r, g, b = 0, c, x
    elseif h < 4 then r, g, b = 0, x, c
    elseif h < 5 then r, g, b = x, 0, c
    else              r, g, b = c, 0, x
    end

    return (r + m), (g + m), (b + m), a
end

function common.get_attr(element, attrname, default)
    return element:get_attribute(attrname, INHERIT[attrname], default)
end

-- parse a color definition, returning the RGBA components in the 0..1 range
function common.color_parse(str, default_r, default_g, default_b, default_a)
    if str == nil then
            return default_r, default_g, default_b, default_a
        end

        if str == "none" then
            return nil, nil, nil, nil
        end

        -- color name
        if COLOR_NAMES[str] ~= nil then
            local color = COLOR_NAMES[str]
            return color[1] / 255, color[2] / 255, color[3] / 255, color[4] / 255

        -- #FFFFFF
        elseif string.match(str,"#......") then
            local red, green, blue = string.match(str,"#(..)(..)(..)")
            red = tonumber(red,16)/255
            green = tonumber(green,16)/255
            blue = tonumber(blue,16)/255
            return red, green, blue, 1

        -- #FFF
        elseif string.match(str,"#...") then
            local red, green, blue = string.match(str,"#(.)(.)(.)")
            red = tonumber(red,16)/15
            green = tonumber(green,16)/15
            blue = tonumber(blue,16)/15
            return red, green, blue, 1

        -- rgb(255, 255, 255)
        elseif string.match(str,"rgb%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)") then
            local red, green, blue = string.match(str,"rgb%((%d+),%s*(%d+),%s*(%d+)%)")
            red = tonumber(red)/255
            green = tonumber(green)/255
            blue = tonumber(blue)/255
            return red, green, blue, 1

        -- rgb(100%, 100%, 100%)
        elseif string.match(str,"rgb%(%s*%d+%%%s*,%s*%d+%%%s*,%s*%d+%%%s*%)") then
            local red, green, blue = string.match(str,"rgb%(%s*(%d+)%%%s*,%s*(%d+)%%%s*,%s*(%d+)%%%s*%)")
            red = tonumber(red)/100
            green = tonumber(green)/100
            blue = tonumber(blue)/100
            return red, green, blue, 1

        -- rgba(255, 255, 255, 1.0)
        elseif string.match(str,"rgba%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*,%s*[^%)%+s]+%s*%)") then
            local red, green, blue, alpha = string.match(str,"rgba%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*([^%)%s]+)%s*%)")
            red = tonumber(red)/255
            green = tonumber(green)/255
            blue = tonumber(blue)/255
            return red, green, blue, tonumber(alpha,10)

        -- rgba(100%, 100%, 100%, 1.0)
        elseif string.match(str,"rgba%(%s*%d+%%%s*,%s*%d+%%%s*,%s*%d+%%%s*,%s*[^%)%s]+%s*%)") then
            local red, green, blue, alpha = string.match(str,"rgba%(%s*(%d+)%%%s*,%s*(%d+)%%%s*,%s*(%d+)%%%s*,%s*([^%)%s]+)%s*%)")
            red = tonumber(red)/100
            green = tonumber(green)/100
            blue = tonumber(blue)/100
            return red, green, blue, tonumber(alpha,10)

        -- Any unsupported format
        else
            return nil, nil, nil, nil
    end
end

function common.transform_parse(svg, transform)
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

            result = result .. "love.graphics.applyTransform(" .. svg:put_data(matrix) .. ")\n"
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

function common.gen_shape_stencil(svg, vertices, fill_rule, clear_stencil, draw_mode)
    if #vertices <= 4 then
        if clear_stencil == true then
            return "love.graphics.clear(false, true, false)\n"
        end

        return ""
    end

    local vertices_pairs = {}
    for i = 1, #vertices, 2 do
        table.insert(vertices_pairs, { vertices[i], vertices[i+1] })
    end

    -- create the Mesh
    local mesh = love.graphics.newMesh(SHAPE_MESH_VERTEX_FORMAT, vertices_pairs, draw_mode or "fan", "static")

    -- output
    local result = nil

    if fill_rule == "nonzero" then
        -- nonzero stencil
        result = [[
            love.graphics.setMeshCullMode("front")
            love.graphics.stencil({fn_draw_mesh}, "incrementwrap", 0, not {clear_stencil})

            love.graphics.setMeshCullMode("back")
            love.graphics.stencil({fn_draw_mesh}, "decrementwrap", 0, true)
        ]]
    elseif fill_rule == "evenodd" then
        -- evenodd stencil
        result = [[
            love.graphics.setMeshCullMode("none")
            love.graphics.stencil({fn_draw_mesh}, "invert", 0, not {clear_stencil})
        ]]
    else
        -- default stencil
        result = [[
            love.graphics.setMeshCullMode("none")
            love.graphics.stencil({fn_draw_mesh}, "replace", 0xFF, not {clear_stencil})
        ]]
    end

    return result
    :gsub("{fn_draw_mesh}", svg:put_function("love.graphics.draw(" .. svg:put_data(mesh) .. ")"))
    :gsub("{clear_stencil}", tostring(clear_stencil ~= false))
end

function common.gen_paint_on_stencil(r, g, b, a)
    return ([[
        love.graphics.setStencilTest("notequal", 0)

        love.graphics.push()
        love.graphics.origin()
        love.graphics.setColor({r}, {g}, {b}, {a})
        love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
        love.graphics.pop()

        love.graphics.setStencilTest()
    ]])
    :gsub("{r}", r)
    :gsub("{g}", g)
    :gsub("{b}", b)
    :gsub("{a}", a)
end

function common.gen_subpath(svg, element, vertices, closed, options)
    -- not enough vertices
    if #vertices < 4 then
        return ""
    end

    -- attributes!

    --  colors (red/green/blue)
    local f_red, f_green, f_blue, f_alpha = common.color_parse(common.get_attr(element, "fill", "black"))
    local s_red, s_green, s_blue, s_alpha = common.color_parse(common.get_attr(element, "stroke", "none"))

    -- opacity
    local opacity = tonumber(common.get_attr(element, "opacity", "1"), 10)

    -- fill properties
    local fill_opacity = tonumber(common.get_attr(element, "fill-opacity", "1"), 10)
    local fill_rule = common.get_attr(element, "fill-rule", "nonzero")

    -- stroke properties
    local stroke_opacity = tonumber(common.get_attr(element, "stroke-opacity", "1"), 10)
    local stroke_width = tonumber(common.get_attr(element, "stroke-width", "1"), 10)
    local stroke_linecap = common.get_attr(element, "stroke-linecap", "butt")
    local stroke_linejoin = common.get_attr(element, "stroke-linejoin", "miter")
    local stroke_miterlimit = tonumber(common.get_attr(element, "stroke-miterlimit", "1"), 10)

    -- check if we're even going to draw anything
    if f_red == nil and s_red == nil then
        return ""
    end

    local result = ""

    -- fill
    if f_red ~= nil and #vertices >= 6 then
        result = result ..
            common.gen_shape_stencil(svg, vertices, fill_rule) ..
            common.gen_paint_on_stencil(f_red, f_green, f_blue, f_alpha * fill_opacity * opacity)
    end

    -- stroke
    if s_red ~= nil and #vertices >= 4 then
        -- stroke the path
        local stroke_slices = stroke(vertices, closed, stroke_width, stroke_linecap, stroke_linejoin, stroke_miterlimit, options)

        if stroke_slices ~= nil then
            -- put each slice on the stencil
            for i = 1, #stroke_slices do
                -- clear the stencil only if we're at the first slice
                -- also, use "triangle strip" as the draw mode
                result = result .. common.gen_shape_stencil(svg, stroke_slices[i], nil, i == 1, "strip")
            end

            -- paint everything!!!!!
            result = result .. common.gen_paint_on_stencil(s_red, s_green, s_blue, s_alpha * stroke_opacity * opacity)
        end
    end

    if options["path_debug"] then
        local r,g,b = common.hsla_to_rgba(math.random(), 1, 0.5)
        result = result .. "love.graphics.setColor(" .. r .. ", " .. g .. ", " .. b .. ", 0.5)\n"
        result = result .. "love.graphics.setPointSize(5)\n"
        result = result .. "love.graphics.points(" .. svg:put_data(vertices) .. ")\n"
    end

    return result
end

function common.gen_path(svg, element, path, options)
    local result = ""

    for i = 1, #(path.subpaths) do
        local sub = path.subpaths[i]

        result = result .. common.gen_subpath(svg, element, sub.vertices, sub.closed, options)
    end

    return result
end

function common.gen(svg, element, options)
    local content = element

    while true do
        local renderer = ELEMENTS[content.name]

        -- No renderer for this element
        if renderer == nil then
            if options.debug then
                print("No renderer for <" .. content.name .. ">")
            end

            return ""
        end

        if renderer == "" then
            renderer = nil
        end

        -- Load the renderer, if any
        if renderer ~= nil then
            renderer = require(cwd .. "svg.renderer." .. ELEMENTS[content.name])
        end

        -- Transform attribute
        local transform = common.get_attr(content, "transform")

        -- Empty elements
        if content.children == nil then
            if renderer == nil or renderer.empty == nil then
                return ""
            end

            content = renderer.empty(content, svg, options)

        -- Containers
        else
            local result = nil
            local state = nil
            local include_children = true

            if renderer ~= nil and renderer.open ~= nil then
                result, state, include_children = renderer.open(content, svg, options)

                include_children = include_children ~= false
            else
                result = ""
            end

            if include_children then
                for i = 1, #(content.children) do
                    result = result .. common.gen(svg, content.children[i], options)
                end
            end

            if renderer ~= nil and renderer.close ~= nil then
                result = result .. renderer.close(content, state, svg, options)
            end

            content = result
        end

        -- If the content is (finally) a string
        if type(content) == "string" then
            -- Apply eventual transform so that everyone doesn't have to do it themselves
            if transform ~= nil then
                content =
                    "love.graphics.push()\n" ..
                    common.transform_parse(svg, transform) ..
                    content ..
                    "love.graphics.pop()\n"
            end

            -- Leave!
            return content
        end
    end
end

return common

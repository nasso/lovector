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
local PathBuilder = require(cwd .. "pathbuilder")
local paint = require(cwd .. "paint")
local vecutils = require(cwd .. "vecutils")
local stroke = require(cwd .. "stroke")

-- create class
local Graphics = {}
Graphics.__index = Graphics

Graphics.mt = {}
Graphics.mt.__index = Graphics.mt
setmetatable(Graphics, Graphics.mt)

-- constants
local DEFAULT_OPTIONS = {
    ["love_lines"] = false;
}

local SHAPE_MESH_VERTEX_FORMAT = {
    { "VertexPosition", "float", 2 }
}

-- constructor
function Graphics.mt.__call(_, ...)
    local self = setmetatable({}, Graphics)

    -- initialize instance
    self:init(...)

    return self
end

-- private methods
--- Adds an arbitrary value to `self.extdata`
local function put_data(self, data)
    table.insert(self.extdata, data)
    return "extdata[" .. #(self.extdata) .. "]"
end

--- Creates a function with the given source code, and adds it to `self.extdata`
local function put_function(self, source)
    return put_data(self, assert(loadstring("local extdata = ...\nreturn function()\n" .. source .. "\nend\n"))(self.extdata))
end

--- Draws a shape on the stencil buffer
local function stencil_mask(self, vertices, clear_stencil)
    assert(vertices)

    -- not enough vertices
    if #vertices <= 4 then
        if clear_stencil == true then
            self.script = self.script .. "love.graphics.clear(false, true, false)\n"
        end

    -- #vertices > 4
    else
        local vertices_pairs = {}
        for i = 1, #vertices, 2 do
            table.insert(vertices_pairs, { vertices[i], vertices[i+1] })
        end

        -- create the Mesh
        local mesh = love.graphics.newMesh(SHAPE_MESH_VERTEX_FORMAT, vertices_pairs, "fan", "static")

        if self.state.fill_rule == "strip" or self.state.fill_rule == "triangles" then
            mesh:setDrawMode(self.state.fill_rule)
        end

        -- output
        local result = nil

        if self.state.fill_rule == "nonzero" then
            -- nonzero stencil
            result = [[
                love.graphics.setMeshCullMode("front")
                love.graphics.stencil({fn_draw_mesh}, "incrementwrap", 0, not {clear_stencil})

                love.graphics.setMeshCullMode("back")
                love.graphics.stencil({fn_draw_mesh}, "decrementwrap", 0, true)
            ]]
        elseif self.state.fill_rule == "evenodd" then
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

        self.script = self.script .. result
        :gsub("{fn_draw_mesh}", put_function(self, "love.graphics.draw(" .. put_data(self, mesh) .. ")"))
        :gsub("{clear_stencil}", tostring(clear_stencil ~= false))
    end

    return self
end

--- Draws a fullscreen rectangle with the given paint, with a stencil test "~= 0"
local function apply_paint(self, paint)
    if paint.type == "color" then
        self.script = self.script .. ([[
            love.graphics.setStencilTest('notequal', 0)

            love.graphics.push()
            love.graphics.origin()
            love.graphics.setColor({r}, {g}, {b}, {a})
            love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
            love.graphics.pop()

            love.graphics.setStencilTest()
        ]])
        :gsub("{r}", paint.r)
        :gsub("{g}", paint.g)
        :gsub("{b}", paint.b)
        :gsub("{a}", paint.a)
    end

    return self
end

-- methods
--- Initializes this Graphics object, as if it was just created
function Graphics:init(options)
    self:release()

    options = options or {}

    for k, v in pairs(DEFAULT_OPTIONS) do
        if options[k] == nil then
            options[k] = v
        end
    end

    self.script = "local extdata = ...\n"
    self.extdata = {}
    self.options = options

    self.state_stack = {}
    self.state = {
        fill_paint = paint.Color(0, 0, 0, 1);
        fill_rule = "nonzero";
        line_caps = "butt";
        line_joins = "miter";
        line_width = 1;
        miter_limit = 4;
        stroke_paint = paint.Color(0, 0, 0, 1);
    }

    return self
end

--- Releases every resource associated with this Graphics object
function Graphics:release()
    if type(self.extdata) == "table" then
        for i = 1, #(self.extdata) do
            local data = self.extdata[i]

            if type(data.release) == "function" then
                data:release()
            end
        end
    end

    self.script = nil
    self.extdata = nil
    self.script_fn = nil
    self.script_fn_src = nil
    self.options = nil

    self.state_stack = nil
    self.state = nil
end

--- Sets self.state.fill_paint
function Graphics:set_fill_paint(value)
    self.state.fill_paint = value

    return self
end

--- Sets self.state.fill_rule
function Graphics:set_fill_rule(value)
    assert(value)

    self.state.fill_rule = value

    return self
end

--- Sets self.state.line_caps
function Graphics:set_line_caps(value)
    assert(value)

    self.state.line_caps = value

    return self
end

--- Sets self.state.line_joins
function Graphics:set_line_joins(value)
    assert(value)

    self.state.line_joins = value

    return self
end

--- Sets self.state.line_width
function Graphics:set_line_width(value)
    assert(value)

    self.state.line_width = value

    return self
end

--- Sets self.state.miter_limit
function Graphics:set_miter_limit(value)
    assert(value)

    self.state.miter_limit = value

    return self
end

--- Sets self.state.stroke_paint
function Graphics:set_stroke_paint(value)
    self.state.stroke_paint = value

    return self
end

--- Pushes the state
function Graphics:push()
    -- push the state to the stack
    table.insert(self.state_stack, self.state)

    -- copy the current state
    local state_cpy = {}
    for k, v in pairs(self.state) do
        state_cpy[k] = v
    end

    -- set the current state to the copy
    self.state = state_cpy

    -- script push
    self.script = self.script .. "love.graphics.push()\n"

    return self
end

--- Pops the state
function Graphics:pop()
    -- pop
    self.state = table.remove(self.state_stack)

    -- script pop
    self.script = self.script .. "love.graphics.pop()\n"

    return self
end

--- Translates the coordinate system
function Graphics:translate(x, y)
    assert(x)
    assert(y)

    self.script = self.script .. "love.graphics.translate(" .. x .. ", " .. y .. ")\n"

    return self
end

--- Rotates the coordinate system. The angle is in radians.
function Graphics:rotate(a, x, y)
    assert(a)

    x = x or 0
    y = y or 0

    if x ~= 0 and y ~= 0 then
        self.script = self.script .. "love.graphics.translate(" .. x .. ", " .. y .. ")\n"
    end

    self.script = self.script .. "love.graphics.rotate(" .. a .. ")\n"

    if x ~= 0 and y ~= 0 then
        self.script = self.script .. "love.graphics.translate(" .. (-x) .. ", " .. (-y) .. ")\n"
    end

    return self
end

--- Scales the coordinate system
function Graphics:scale(x, y)
    assert(x)

    y = y or x

    self.script = self.script .. "love.graphics.scale(" .. x .. ", " .. y .. ")\n"

    return self
end

--- Applies the matrix to the coordinate system
function Graphics:apply_transform(a, b, c, d, e, f)
    assert(a)
    assert(b)
    assert(c)
    assert(d)
    assert(e)
    assert(f)

    local matrix = love.math.newTransform()
    matrix:setMatrix(
        a, c, 0, e,
        b, d, 0, f,
        0, 0, 1, 0,
        0, 0, 0, 1
    )

    self.script = self.script .. "love.graphics.applyTransform(" .. put_data(self, matrix) .. ")\n"

    return self
end

--- Shears the coordinate system. Angles are in radians.
function Graphics:shear(x, y)
    assert(x)
    assert(y)

    self.script = self.script .. "love.graphics.shear(" .. x .. ", " .. y .. ")\n"

    return self
end

--- Fills the shape described by the given vertices
function Graphics:fill_vertices(vertices)
    assert(vertices)

    if #vertices >= 6 then
        stencil_mask(self, vertices)
        apply_paint(self, self.state.fill_paint)
    end

    return self
end

--- Draws the outline of the shape described by the given vertices, closing it if `closed` is true
function Graphics:stroke_vertices(vertices, closed)
    assert(vertices)

    closed = closed or false

    if self.state.stroke_paint and #vertices >= 4 then
        if self.options["love_lines"] then
            local bufferid = put_data(self, vecutils.prune_small_lines(vertices, closed, 1/1000))

            self.script = self.script .. "love.graphics.setLineWidth(" .. self.state.line_width .. ")\n"

            local fn_draw_lines = ""

            if closed then
                fn_draw_lines = "love.graphics.polygon(\"line\", " .. bufferid .. ")\n"
            else
                fn_draw_lines = "love.graphics.line(" .. bufferid .. ")\n"
            end

            self.script = self.script .. "love.graphics.stencil(" .. put_function(self, fn_draw_lines) .. ", 'replace', 0xFF)\n"
            apply_paint(self, self.state.stroke_paint)
        else
            -- fill the stroke
            local stroke_path = stroke.gen_strips(vertices, closed, self.state.line_width, self.state.line_caps, self.state.line_joins, self.state.miter_limit, self.options)

            if #(stroke_path.subpaths) > 0 then
                -- set the fill_rule to "strip"
                local old_fill_rule = self.state.fill_rule
                self.state.fill_rule = "strip"

                for i = 1, #(stroke_path.subpaths) do
                    local sub = stroke_path.subpaths[i]

                    if #(sub.vertices) >= 6 then
                        -- clear the stencil if i == 1 (only for the first subpath)
                        stencil_mask(self, sub.vertices, i == 1)
                    end
                end

                -- restore previous fill_rule
                self.state.fill_rule = old_fill_rule

                apply_paint(self, self.state.stroke_paint)
            end
        end
    end

    return self
end

--- Fills and/or draws the outline of the given path, according to the current stroke_paint and fill_paint
function Graphics:draw_vertices(vertices, closed)
    assert(vertices)

    if self.state.fill_paint ~= nil then
        self:fill_vertices(vertices)
    end

    if self.state.stroke_paint ~= nil then
        self:stroke_vertices(vertices, closed)
    end
end

--- Fills the given path
function Graphics:fill_path(path)
    assert(path)

    for i = 1, #(path.subpaths) do
        local sub = path.subpaths[i]

        self:fill_vertices(sub.vertices)
    end

    return self
end

--- Draws the outline of the given path
function Graphics:stroke_path(path)
    assert(path)

    for i = 1, #(path.subpaths) do
        local sub = path.subpaths[i]

        self:stroke_vertices(sub.vertices, sub.closed, self.state.line_width, self.state.line_caps, self.state.line_joins, self.state.miter_limit)
    end

    return self
end

--- Fills and/or draws the outline of the given path, according to the current stroke_paint and fill_paint
function Graphics:draw_path(path)
    assert(path)

    if self.state.fill_paint ~= nil then
        self:fill_path(path)
    end

    if self.state.stroke_paint ~= nil then
        self:stroke_path(path)
    end
end

--- Actually draws this Graphics object
function Graphics:draw(x, y, sx, sy)
    assert(self.script, "Graphics object is invalid. It has probably been released.")

    if self.script_fn_src ~= self.script then
        self.script_fn_src = self.script
        self.script_fn = assert(loadstring(self.script_fn_src))
    end

    x = x   or 0
    y = y   or 0
    sx = sx or 1
    sy = sy or sx

    -- push graphics settings
    love.graphics.push()

    -- position
    love.graphics.translate(x, y)

    -- scale
    if sx ~= nil then
        love.graphics.scale(sx, sy)
    end

    -- draw
    self.script_fn(self.extdata)

    -- reset graphics
    love.graphics.pop()
end

return Graphics

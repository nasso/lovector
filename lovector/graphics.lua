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
--- Adds an arbitrary value to `self.extdata`.
local function put_data(self, data)
    table.insert(self.extdata, data)
    return "extdata[" .. #(self.extdata) .. "]"
end

--- Creates a function with the given source code, and adds it to `self.extdata`.
local function put_function(self, source)
    return put_data(
        self,
        assert(loadstring("local extdata = ...\nreturn function()\n" .. source .. "\nend\n"))(self.extdata)
    )
end

--- Fills a shape on the stencil buffer.
local function stencil_fill_mask(self, vertices, clear_stencil)
    assert(vertices)

    if clear_stencil == nil then
        clear_stencil = true
    end

    local empty = true

    -- not enough vertices
    if #vertices < 6 then
        if clear_stencil then
            self.script = self.script .. "love.graphics.clear(false, true, false)\n"
        end

    -- #vertices >= 6
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
                love.graphics.stencil({fn_draw_mesh}, "incrementwrap", 0, {keep_stencil})

                love.graphics.setMeshCullMode("back")
                love.graphics.stencil({fn_draw_mesh}, "decrementwrap", 0, true)
            ]]
        elseif self.state.fill_rule == "evenodd" then
            -- evenodd stencil
            result = [[
                love.graphics.setMeshCullMode("none")
                love.graphics.stencil({fn_draw_mesh}, "invert", 0, {keep_stencil})
            ]]
        else
            -- default stencil
            result = [[
                love.graphics.setMeshCullMode("none")
                love.graphics.stencil({fn_draw_mesh}, "replace", 0xFF, {keep_stencil})
            ]]
        end

        self.script = self.script .. result
            :gsub("{fn_draw_mesh}", put_function(self, "love.graphics.draw(" .. put_data(self, mesh) .. ")"))
            :gsub("{keep_stencil}", tostring(not clear_stencil))

        empty = false
    end

    return empty
end

--- Strokes a shape on the stencil buffer.
local function stencil_stroke_mask(self, vertices, closed, clear_stencil)
    if clear_stencil == nil then
        clear_stencil = true
    end

    local empty = true

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

            self.script = self.script ..
                "love.graphics.stencil(" ..
                    put_function(self, fn_draw_lines) .. ", 'replace', 0xFF, " .. tostring(not clear_stencil) ..
                ")\n"
            empty = false
        else
            -- fill the stroke
            local stroke_path = stroke.gen_strips(
                vertices, closed,
                self.state.line_width,
                self.state.line_caps,
                self.state.line_joins,
                self.state.miter_limit,
                self.options
            )

            -- set the fill_rule to "strip"
            local old_fill_rule = self.state.fill_rule
            self.state.fill_rule = "strip"

            for i = 1, #(stroke_path.subpaths) do
                local sub = stroke_path.subpaths[i]

                -- clear the stencil only for the first non-empty subpath
                local sub_empty = stencil_fill_mask(self, sub.vertices, clear_stencil and empty)
                empty = empty and sub_empty
            end

            -- restore previous fill_rule
            self.state.fill_rule = old_fill_rule
        end
    end

    return empty
end

--- Draws a fullscreen rectangle with the given paint, with a stencil test "~= 0".
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
end

-- methods
--- Initializes this Graphics object, as if it was just created.
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

    self.current_path = nil

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

    self:begin_path()

    return self
end

--- Releases every resource associated with this Graphics object.
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

--- State

--- Pushes the state.
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

--- Pops the state.
function Graphics:pop()
    -- pop
    self.state = table.remove(self.state_stack)

    -- script pop
    self.script = self.script .. "love.graphics.pop()\n"

    return self
end

--- Sets `self.state.fill_paint`.
function Graphics:set_fill_paint(value)
    self.state.fill_paint = value

    return self
end

--- Sets `self.state.fill_rule`.
function Graphics:set_fill_rule(value)
    assert(value)

    self.state.fill_rule = value

    return self
end

--- Sets `self.state.line_caps`.
function Graphics:set_line_caps(value)
    assert(value)

    self.state.line_caps = value

    return self
end

--- Sets `self.state.line_joins`.
function Graphics:set_line_joins(value)
    assert(value)

    self.state.line_joins = value

    return self
end

--- Sets `self.state.line_width`.
function Graphics:set_line_width(value)
    assert(value)

    self.state.line_width = value

    return self
end

--- Sets `self.state.miter_limit`.
function Graphics:set_miter_limit(value)
    assert(value)

    self.state.miter_limit = value

    return self
end

--- Sets `self.state.stroke_paint`.
function Graphics:set_stroke_paint(value)
    self.state.stroke_paint = value

    return self
end

--- Transformations

--- Translates the coordinate system.
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

--- Scales the coordinate system.
function Graphics:scale(x, y)
    assert(x)

    y = y or x

    self.script = self.script .. "love.graphics.scale(" .. x .. ", " .. y .. ")\n"

    return self
end

--- Applies the matrix to the coordinate system.
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

--- Paths

--- Resets the current path.
function Graphics:begin_path()
    self.current_path = PathBuilder(self.options)

    return self
end

--- Creates a new subpath with the given point.
function Graphics:move_to(x, y)
    self.current_path:move_to(x, y)
    return self
end

--- Marks the current subpath as closed, and starts a new subpath with a point the same as the start and end of the
--- newly closed subpath.
function Graphics:close_path()
    self.current_path:close_path()
    return self
end

--- Adds the given point to the current subpath, connected to the previous one by a straight line.
function Graphics:line_to(x, y)
    self.current_path:line_to(x, y)
    return self
end

--- Adds the given point to the current subpath, connected to the previous one by a quadratic Bézier curve with the
--- given control point.
function Graphics:quadratic_curve_to(cpx, cpy, x, y)
    self.current_path:quadratic_curve_to(cpx, cpy, x, y)
    return self
end

--- Adds the given point to the current subpath, connected to the previous one by a cubic Bézier curve with the given
--- control points.
function Graphics:bezier_curve_to(cp1x, cp1y, cp2x, cp2y, x, y)
    self.current_path:bezier_curve_to(cp1x, cp1y, cp2x, cp2y, x, y)
    return self
end

--- Draws an elliptical arc from the current point to (x, y). The size and orientation of the ellipse are defined by two
--- radii (rx, ry) and an x-axis-rotation, which indicates how the ellipse as a whole is rotated, in degrees, relative
--- to the current coordinate system. The center (cx, cy) of the ellipse is calculated automatically to satisfy the
--- constraints imposed by the other parameters. large-arc-flag and sweep-flag contribute to the automatic calculations
--- and help determine how the arc is drawn.
function Graphics:elliptical_arc_to(rx, ry, phi, fa, fs, x, y)
    self.current_path:elliptical_arc_to(rx, ry, phi, fa, fs, x, y)
    return self
end

--- Adds points to the subpath such that the arc described by the circumference of the circle described by the
--- arguments, starting at the given start angle and ending at the given end angle, going in the given direction
--- (defaulting to clockwise), is added to the path, connected to the previous point by a straight line.
function Graphics:arc(x, y, radius, start_angle, end_angle, counterclockwise)
    self.current_path:arc(x, y, radius, start_angle, end_angle, counterclockwise)
    return self
end

--- Same as arc(), but allows differents radii on the horizontal and vertical axis and a rotation angle.
function Graphics:elliptical_arc(cx, cy, rx, ry, start_angle, end_angle, counterclockwise, rotation)
    self.current_path:elliptical_arc(cx, cy, rx, ry, start_angle, end_angle, counterclockwise, rotation)
    return self
end

--- Adds a new closed subpath to the path, representing the given rectangle.
function Graphics:rect(x, y, w, h)
    self.current_path:rect(x, y, w, h)
    return self
end

--- Drawing

--- Fills the shape described by the given vertices.
function Graphics:fill_vertices(vertices)
    assert(vertices)

    local empty = stencil_fill_mask(self, vertices)

    if not empty then
        apply_paint(self, self.state.fill_paint)
    end

    return self
end

--- Draws the outline of the shape described by the given vertices, closing it if `closed` is true.
function Graphics:stroke_vertices(vertices, closed)
    assert(vertices)

    local empty = stencil_stroke_mask(self, vertices, closed or false)

    if not empty then
        apply_paint(self, self.state.stroke_paint)
    end

    return self
end

--- Fills and/or draws the outline of the given path, according to the current stroke_paint and fill_paint.
function Graphics:draw_vertices(vertices, closed)
    assert(vertices)

    if self.state.fill_paint ~= nil then
        self:fill_vertices(vertices)
    end

    if self.state.stroke_paint ~= nil then
        self:stroke_vertices(vertices, closed or false)
    end
end

--- Fills the given path.
function Graphics:fill_path(path)
    path = path or self.current_path

    local empty = true

    for i = 1, #(path.subpaths) do
        local sub = path.subpaths[i]

        local sub_empty = stencil_fill_mask(self, sub.vertices, empty)
        empty = empty and sub_empty
    end

    if not empty then
        apply_paint(self, self.state.fill_paint)
    end

    return self
end

--- Draws the outline of the given path.
function Graphics:stroke_path(path)
    path = path or self.current_path

    local empty = true

    for i = 1, #(path.subpaths) do
        local sub = path.subpaths[i]

        local sub_empty = stencil_stroke_mask(self, sub.vertices, sub.closed, empty)
        empty = empty and sub_empty
    end

    if not empty then
        apply_paint(self, self.state.stroke_paint)
    end

    return self
end

--- Fills and/or draws the outline of the given path, according to the current stroke_paint and fill_paint.
function Graphics:draw_path(path)
    path = path or self.current_path

    if self.state.fill_paint ~= nil then
        self:fill_path(path)
    end

    if self.state.stroke_paint ~= nil then
        self:stroke_path(path)
    end
end

--- Effectively drawing

--- Actually draws this Graphics object.
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

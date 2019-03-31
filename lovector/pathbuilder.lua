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

local PathBuilder = {}
PathBuilder.__index = PathBuilder

PathBuilder.mt = {}
PathBuilder.mt.__index = PathBuilder.mt
setmetatable(PathBuilder, PathBuilder.mt)

-- constants
local DEFAULT_OPTIONS = {
    ["arc_segments"] = 50;
    ["bezier_depth"] = 5;
}

-- private functions
local function vec_angle(ux, uy, vx, vy)
    -- this function assumes u and v have a length of 1
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

local function endpoint_to_center(x1, y1, x2, y2, fa, fs, rx, ry, phi)
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
    local vx = (x1_ - cx_) / rx
    local vy = (y1_ - cy_) / ry

    local theta1 = vec_angle(1, 0, vx, vy)
    local dtheta = vec_angle(vx, vy, (-x1_ - cx_) / rx, (-y1_ - cy_) / ry) % 360

    if not fs and dtheta > 0 then
        dtheta = dtheta - 360
    elseif fs and dtheta < 0 then
        dtheta = dtheta + 360
    end

    return cx, cy, theta1, dtheta
end

-- constructor
function PathBuilder.mt.__call(_, ...)
    local self = setmetatable({}, PathBuilder)

    self:init(...)

    return self
end

-- methods
function PathBuilder:init(options)
    self.options = options or {}

    for k, v in pairs(DEFAULT_OPTIONS) do
        if self.options[k] == nil then
            self.options[k] = v
        end
    end

    self.subpaths = {}
    self.current_subpath = nil
    self.stroke_shape = nil

    return self
end

function PathBuilder:last_point()
    if self.current_subpath == nil then
        return 0, 0
    end

    local count = #(self.current_subpath.vertices)

    if count < 2 then
        return 0, 0
    end

    return self.current_subpath.vertices[count - 1], self.current_subpath.vertices[count]
end

function PathBuilder:ensure_sub_path(x, y)
    if #(self.subpaths) == 0 then
        self:move_to(x, y)
    end

    return self
end

function PathBuilder:move_to(x, y)
    self.current_subpath = {
        vertices = { x, y };
        closed = false;
    }

    table.insert(self.subpaths, self.current_subpath)

    return self
end

function PathBuilder:close_path()
    if self.current_subpath ~= nil then
        self.current_subpath.closed = true

        if #(self.current_subpath.vertices) >= 2 then
            self:move_to(self.current_subpath.vertices[1], self.current_subpath.vertices[2])
        end
    end

    return self
end

function PathBuilder:line_to(x, y)
    if self.current_subpath == nil then
        self:ensure_sub_path(x, y)
    else
        table.insert(self.current_subpath.vertices, x)
        table.insert(self.current_subpath.vertices, y)
    end

    return self
end

function PathBuilder:rect(x, y, w, h)
    self:move_to(x, y)
    self:line_to(x + w, y)
    self:line_to(x + w, y + h)
    self:line_to(x, y + h)
    self:close_path()
    self:move_to(x, y)

    return self
end

function PathBuilder:quadratic_curve_to(cpx, cpy, x, y)
    self:ensure_sub_path(cpx, cpy)

    local spx, spy = self:last_point()

    -- generate vertices
    local curve = love.math.newBezierCurve(spx, spy, x, y)
    curve:insertControlPoint(cpx, cpy)

    local verts = curve:render(self.options["bezier_depth"])

    -- don't include the first point as it is just the last one
    for i = 3, #verts do
        table.insert(self.current_subpath.vertices, verts[i])
    end

    -- release object
    curve:release()

    return self
end

function PathBuilder:bezier_curve_to(cp1x, cp1y, cp2x, cp2y, x, y)
    self:ensure_sub_path(cp1x, cp1y)

    local spx, spy = self:last_point()

    -- generate vertices
    local curve = love.math.newBezierCurve(spx, spy, x, y)
    curve:insertControlPoint(cp1x, cp1y)
    curve:insertControlPoint(cp2x, cp2y)

    local verts = curve:render(self.options["bezier_depth"])

    -- don't include the first point as it is just the last one
    for i = 3, #verts do
        table.insert(self.current_subpath.vertices, verts[i])
    end

    -- release object
    curve:release()

    return self
end

function PathBuilder:elliptical_arc_to(rx, ry, phi, fa, fs, x, y)
    self:ensure_sub_path(x, y)

    local sx, sy = self:last_point()

    -- argument checking
    local segments = math.max(self.options["arc_segments"], 1)

    -- out-of-range checks

    -- same points
    if sx == x and sy == y then
        return self
    end

    -- zero radii
    if rx == 0 or ry == 0 then
        table.insert(self.current_subpath.vertices, x)
        table.insert(self.current_subpath.vertices, y)
        return self
    end

    -- negative radii
    rx = math.abs(rx)
    ry = math.abs(ry)

    -- too small radii
    local rad_phi = math.rad(phi)
    local cos_phi = math.cos(rad_phi)
    local sin_phi = math.sin(rad_phi)

    local x1_ = cos_phi * (sx-x)/2 + sin_phi * (sy-y)/2
    local y1_ = -sin_phi * (sx-x)/2 + cos_phi * (sy-y)/2

    local lambda = x1_*x1_/(rx*rx) + y1_*y1_/(ry*ry)

    if lambda > 1 then
        local sqrt_lambda = math.sqrt(lambda)

        rx = sqrt_lambda * rx
        ry = sqrt_lambda * ry
    end

    -- take phi mod 360
    phi = phi % 360

    local cx, cy, theta1, dtheta = endpoint_to_center(sx, sy, x, y, fa, fs, rx, ry, phi)

    self:elliptical_arc(cx, cy, rx, ry, theta1, theta1 + dtheta, dtheta < 0, phi)

    return self
end

function PathBuilder:arc(x, y, radius, start_angle, end_angle, counterclockwise)
    return self:elliptical_arc(x, y, radius, radius, start_angle, end_angle, counterclockwise, rotation)
end

function PathBuilder:elliptical_arc(cx, cy, rx, ry, start_angle, end_angle, counterclockwise, rotation)
    self:ensure_sub_path()

    local segments = math.max(self.options["arc_segments"], 1)

    counterclockwise = counterclockwise or false

    local dtheta = end_angle - start_angle

    -- when it's the whole circumference
    if
        (not counterclockwise and dtheta >= 360) or
        (counterclockwise and dtheta <= -360)
    then
        dtheta = math.min(360, math.max(-360, dtheta))
    end

    if counterclockwise ~= (dtheta < 0) then
        dtheta = -dtheta
        start_angle = end_angle
    end

    -- rotation
    local rad_phi = math.rad((rotation or 0) % 360)
    local cos_phi = math.cos(rad_phi)
    local sin_phi = math.sin(rad_phi)

    -- build it
    for i = 0, segments do
        local theta = math.rad(start_angle + dtheta * (i / segments))
        local cos_theta = math.cos(theta)
        local sin_theta = math.sin(theta)

        table.insert(self.current_subpath.vertices, cos_phi * rx * cos_theta - sin_phi * ry * sin_theta + cx)
        table.insert(self.current_subpath.vertices, sin_phi * rx * cos_theta + cos_phi * ry * sin_theta + cy)
    end

    return self
end

return PathBuilder

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
local vecutils = require(cwd .. "vecutils")

local stroke = {}

local DEFAULT_OPTIONS = {
    ["stroke_segment_min_length"] = 1 / 1000;
    ["stroke_join_discard_threshold"] = 1 / 5;
    ["stroke_arc_segments"] = 20;
}

local function build_vertices_table(vertices)
    local copy =  {}

    for i = 1, #vertices, 2 do
        table.insert(copy, {
            x = vertices[i];
            y = vertices[i + 1];
        })
    end

    return copy
end

local function get_direction(a, b)
    -- direction
    local dx = b.x - a.x
    local dy = b.y - a.y

    -- length
    local len = math.sqrt(dx * dx + dy * dy)

    -- normalize direction
    dx = dx / len
    dy = dy / len

    return dx, dy
end

local function get_bisector(a, b, c)
    -- direction
    local ba_x, ba_y = get_direction(b, a)
    local bc_x, bc_y = get_direction(b, c)

    -- length of BA and BC
    local ba_len = math.sqrt(ba_x * ba_x + ba_y * ba_y)
    local bc_len = math.sqrt(bc_x * bc_x + bc_y * bc_y)

    -- normalize BA and BC
    ba_x = ba_x / ba_len
    ba_y = ba_y / ba_len
    bc_x = bc_x / bc_len
    bc_y = bc_y / bc_len

    -- calculate BD (D is a point of the bisector that isn't B)
    local bd_x = ba_x + bc_x
    local bd_y = ba_y + bc_y

    -- length of BD
    local bd_len = math.sqrt(bd_x * bd_x + bd_y * bd_y)

    -- normalize BD
    bd_x = bd_x / bd_len
    bd_y = bd_y / bd_len

    return bd_x, bd_y
end

local function create_join(a, b, c)
    b.join = true
    b.previous = a
    b.next = c
    b.dx1, b.dy1 = get_direction(b, a)
    b.dx2, b.dy2 = get_direction(b, c)
    b.bx, b.by = get_bisector(a, b, c)
end

local function generate_joins(vertices)
    for i = 2, (#vertices - 1) do
        local a = vertices[i - 1]
        local b = vertices[i]
        local c = vertices[i + 1]

        -- add join
        create_join(a, b, c)
    end
end

local function close_shape(path)
    local first = path[1]
    local last = path[#path]

    -- join first point with end point
    create_join(last, first, path[2])

    -- join end point with first point
    create_join(path[#path - 1], last, first)
end

local function generate_caps(path)
    local first = path[1]
    local last = path[#path]

    -- start cap
    first.cap = true
    first.previous = nil
    first.next = path[2]
    first.dx, first.dy = get_direction(first, first.next)

    -- end cap
    last.cap = true
    last.previous = path[#path - 1]
    last.next = nil
    last.dx, last.dy = get_direction(last.previous, last)
end

function stroke.gen_strips(path, closed, width, line_cap, line_join, miter_limit, options)
    -- a single point or less gives no line
    if #path <= 2 then
        return nil
    end

    -- default options
    options = options or {}

    for k, v in pairs(DEFAULT_OPTIONS) do
        if options[k] == nil then
            options[k] = v
        end
    end

    -- build a { x = ...; y = ...; } table from a { x, y, x, y, x, y }
    path = build_vertices_table(path)

    -- prune zero-length segments
    vecutils.prune_small_lines_xy(path, closed, options["stroke_segment_min_length"])

    -- generate joins
    generate_joins(path)

    -- add the joins if closed
    if closed then
        close_shape(path)
    else
        generate_caps(path)
    end

    -- vertice list
    local half_width = width / 2

    local vertices = PathBuilder(options)

    local p = path[1]

    local stroke_join_discard_threshold = options["stroke_join_discard_threshold"]
    local stroke_arc_segments = options["stroke_arc_segments"]

    repeat
        if p.join == true then
            local cross = p.dx1 * p.dy2 - p.dx2 * p.dy1

            -- first perpendicular segment of the join
            -- the one that's "coming" from the previous line
            vertices:line_to(p.x + p.dy1 * half_width, p.y - p.dx1 * half_width)
            vertices:line_to(p.x - p.dy1 * half_width, p.y + p.dx1 * half_width)

            -- only proceed if the angle difference is big enough
            if math.abs(cross) > stroke_join_discard_threshold then
                if line_join == "miter" then
                    -- miter length (length between the intersections of the outer-lines)
                    local miter_len = half_width / math.cos(vecutils.vec_angle(-p.dx1, -p.dy1, p.dx2, p.dy2) / 2)

                    -- ratio that can't exceed the miter_limit
                    local ratio = miter_len / half_width

                    if ratio < miter_limit then
                        vertices:line_to(p.x - p.bx * miter_len, p.y - p.by * miter_len)
                    end
                elseif line_join == "round" then
                    -- "outer" vertices (those on the bigger side of the angle) are...
                    local a_x = 0
                    local a_y = 0
                    local b_x = 0
                    local b_y = 0

                    -- ...either on one side...
                    if cross > 0 then
                        a_x = p.dy1
                        a_y = -p.dx1

                        b_x = -p.dy2
                        b_y = p.dx2

                    -- ...or the other
                    else
                        a_x = -p.dy1
                        a_y = p.dx1

                        b_x = p.dy2
                        b_y = -p.dx2
                    end

                    local start_angle = vecutils.vec_angle(a_x, a_y, 1, 0)
                    local dtheta = vecutils.vec_angle(a_x, a_y, b_x, b_y)

                    -- add every point of the arc
                    for i = 0, stroke_arc_segments do
                        local theta = start_angle - dtheta * (i / stroke_arc_segments)
                        local cos_theta = math.cos(theta)
                        local sin_theta = math.sin(theta)

                        vertices:line_to(p.x + cos_theta * half_width, p.y - sin_theta * half_width)

                        if i ~= stroke_arc_segments then
                            vertices:line_to(p.x, p.y)
                        end
                    end
                end

                -- second perpendicular segment of the join
                -- the one that's "going out" to the next line
                vertices:line_to(p.x - p.dy2 * half_width, p.y + p.dx2 * half_width)
                vertices:line_to(p.x + p.dy2 * half_width, p.y - p.dx2 * half_width)
            end
        elseif p.cap == true then
            -- "butt" line cap
            if line_cap == "butt" then
                vertices:line_to(p.x - p.dy * half_width, p.y + p.dx * half_width)
                vertices:line_to(p.x + p.dy * half_width, p.y - p.dx * half_width)

            -- "square" line cap
            elseif line_cap == "square" then
                local side = (p.next == nil) and 1 or -1

                vertices:line_to(p.x + (p.dx * side - p.dy) * half_width, p.y + (p.dy * side + p.dx) * half_width)
                vertices:line_to(p.x + (p.dx * side + p.dy) * half_width, p.y + (p.dy * side - p.dx) * half_width)

            -- "round" line cap
            elseif line_cap == "round" then
                local side = (p.next == nil) and 0 or 1

                -- similar to round joins
                local start_angle = vecutils.vec_angle(-p.dy, p.dx, 1, 0)

                -- add every point of the arc
                for i = 0, stroke_arc_segments do
                    local per = i / stroke_arc_segments - side

                    local theta = start_angle - math.pi * 0.5 * per
                    local phi = start_angle - math.pi * (1.0 - 0.5 * per)

                    vertices:line_to(p.x - math.cos(phi) * half_width, p.y + math.sin(phi) * half_width)
                    vertices:line_to(p.x - math.cos(theta) * half_width, p.y + math.sin(theta) * half_width)
                end
            end
        end

        p = p.next
    until p == nil or p == path[1]

    -- close the shape
    if closed then
        vertices:line_to(p.x + p.dy1 * half_width, p.y - p.dx1 * half_width)
        vertices:line_to(p.x - p.dy1 * half_width, p.y + p.dx1 * half_width)
    end

    return vertices
end

return stroke

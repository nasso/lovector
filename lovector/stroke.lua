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

local DEFAULT_OPTIONS = {
    ["stroke_segment_min_length"] = 1 / 1000;
}

local function copy_vertices(vertices)
    local copy =  {}

    for i = 1, #vertices, 2 do
        table.insert(copy, {
            x = vertices[i];
            y = vertices[i + 1];
        })
    end

    return copy
end

local function euclidian_distance_squared(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    return dx * dx + dy * dy
end

local function prune_small_lines(vertices, closed, min_len)
    -- default length to 0
    min_len = min_len or 0

    -- square the length so that we don't have to take the sqrt of distances
    min_len = min_len * min_len

    -- add all the others
    local i = 1
    while i <= #vertices do
        local a = vertices[i]
        local b = vertices[i + 1]

        if i == #vertices then
            if closed then
                b = vertices[1]
            else
                break
            end
        end

        if euclidian_distance_squared(a, b) < min_len then
            -- remove this point
            table.remove(vertices, i)

            -- move the end point to the middle of the line
            b.x = (a.x + b.x) / 2
            b.y = (a.y + b.y) / 2
        else
            -- move to the next line
            i = i + 1
        end
    end
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
    local dx = (a.x + c.x) - b.x
    local dy = (a.y + c.y) - b.y

    -- length
    local len = math.sqrt(dx * dx + dy * dy)

    -- normalize direction
    dx = dx / len
    dy = dy / len

    return dx, dy
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

local function stroke(path, closed, width, linecap, linejoin, miterlimit, options)
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

    -- copy the path
    path = copy_vertices(path)

    -- prune zero-length
    prune_small_lines(path, closed, options["stroke_segment_min_length"])

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

    local vertices = {}

    local p = path[1]

    repeat
        if p.join == true then
            table.insert(vertices, p.x + p.dy1 * half_width)
            table.insert(vertices, p.y - p.dx1 * half_width)

            table.insert(vertices, p.x - p.dy1 * half_width)
            table.insert(vertices, p.y + p.dx1 * half_width)

            table.insert(vertices, p.x - p.dy2 * half_width)
            table.insert(vertices, p.y + p.dx2 * half_width)

            table.insert(vertices, p.x + p.dy2 * half_width)
            table.insert(vertices, p.y - p.dx2 * half_width)
        elseif p.cap == true then
            -- ~~fluffy~~ butt
            table.insert(vertices, p.x - p.dy * half_width)
            table.insert(vertices, p.y + p.dx * half_width)

            table.insert(vertices, p.x + p.dy * half_width)
            table.insert(vertices, p.y - p.dx * half_width)
        end

        p = p.next
    until p == nil or p == path[1]

    if closed then
        table.insert(vertices, p.x + p.dy1 * half_width)
        table.insert(vertices, p.y - p.dx1 * half_width)

        table.insert(vertices, p.x - p.dy1 * half_width)
        table.insert(vertices, p.y + p.dx1 * half_width)
    end

    -- since there's no support for dashes yet, return a single slice
    return { vertices }
end

return stroke

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

local vecutils = {}

function vecutils.clone_vertices_table(vertices)
    local copy = {}

    -- for each pair of x, y (discards any leading coordinate if the table
    -- length is odd)
    for i = 1, #vertices - 1, 2 do
        table.insert(copy, vertices[i])
        table.insert(copy, vertices[i + 1])
    end

    return copy
end

function vecutils.vec_angle(ux, uy, vx, vy)
    -- this function assumes u and v have a length of 1
    local cross = ux * vy - uy * vx
    local dot = ux * vx + uy * vy

    -- clamp it to avoid floating-point arithmetics errors
    dot = math.min(1, math.max(-1, dot))

    local result = math.acos(dot)

    if cross >= 0 then
        return result
    else
        return -result
    end
end

function vecutils.euclidian_distance_squared(a_x, a_y, b_x, b_y)
    local dx = b_x - a_x
    local dy = b_y - a_y
    return dx * dx + dy * dy
end

function vecutils.prune_small_lines(vertices, closed, min_len)
    local result = vecutils.clone_vertices_table(vertices)

    -- default length to 0
    min_len = min_len or 0

    -- square the length so that we don't have to take the sqrt of distances
    min_len = min_len * min_len

    -- add all the others
    local i = 1
    while i <= #result - 1 do
        local bi = i + 2

        if i == #result - 1 then
            if closed then
                bi = 1
            else
                break
            end
        end

        local a_x, a_y = result[i], result[i + 1]
        local b_x, b_y = result[bi], result[bi + 1]

        if vecutils.euclidian_distance_squared(a_x, a_y, b_x, b_y) < min_len then
            -- move the end point to the middle of the line
            result[bi] = (a_x + b_x) / 2
            result[bi + 1] = (a_y + b_y) / 2

            -- remove this point
            table.remove(result, i)
            table.remove(result, i)
        else
            -- move to the next line
            i = i + 2
        end
    end

    return result
end

-- same as prune_small_lines, but each vertex is a { x = ...; y = ...; } table
function vecutils.prune_small_lines_xy(vertices, closed, min_len)
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

        if vecutils.euclidian_distance_squared(a.x, a.y, b.x, b.y) < min_len then
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

return vecutils

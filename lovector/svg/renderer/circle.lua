local cwd = (...):match('(.*lovector).-$') .. "."
local PathBuilder = require(cwd .. "pathbuilder")
local common = require(cwd .. "svg.common")

local renderer = {}

function renderer:empty(svg, options)
    local cx = tonumber(common.get_attr(self, "cx", "0"), 10)
    local cy = tonumber(common.get_attr(self, "cy", "0"), 10)
    local r = tonumber(common.get_attr(self, "r", "0"), 10)

    if r <= 0 then
        return ""
    end

    local path = PathBuilder(options)

    path:arc(cx, cy, r, 0, 360)

    local result = ""

    for i = 1, #(path.subpaths) do
        local sub = path.subpaths[i]

        result = result .. common.gen_subpath(svg, self, sub.vertices, sub.closed, options)
    end

    return result
end

return renderer

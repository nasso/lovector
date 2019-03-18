local cwd = (...):match('(.-lovector).*$') .. "."

local svgparse = require(cwd .. "svgparse")

local lovector = {}

lovector.SVG = {}
lovector.SVG.__index = lovector.SVG

function lovector.SVG:draw(x, y, sx, sy)
    if x  == nil then x  = 0  end
    if y  == nil then y  = 0  end
    if sx == nil then sx = 1  end
    if sy == nil then sy = sx end

    -- a viewport width/height of 0 disables drawing
    if self.viewport == nil or (self.viewport.width ~= 0 and self.viewport.height ~= 0) then
        -- push graphics settings
        love.graphics.push()

        -- position
        love.graphics.translate(x or 0, y or 0)

        -- scale
        if sx ~= nil then
            love.graphics.scale(sx, sy)
        end

        -- SVG viewBox handling
        if self.viewport ~= nil then
            love.graphics.translate(-self.viewport.minx, -self.viewport.miny)
            love.graphics.scale(self.width / self.viewport.width, self.height / self.viewport.height)
        end

        -- draw
        self.draw_function(self.extdata)

        -- reset graphics
        love.graphics.pop()
    end
end

function lovector.loadsvg(svg, options)
    -- if the svg argument is a path, load it
    if not svg:match("<?xml") then
        local contents, err = love.filesystem.read(svg)

        if contents == nil then
            error(err)
        end

        svg = contents
    end

    -- parse
    svg = svgparse(svg, options)

    return setmetatable(svg, lovector.SVG)
end

return lovector

local cwd = (...):match('(.-)[^%.]+$')

local utils = require(cwd .. "utils")
local xmlparse = require(cwd .. "xmlparse")

local function svgparse(source, options)
    local svg = {
        width = 0;
        height = 0;
        viewport = nil;
        extdata = {};
        draw_function = 'local extdata = ...\n';
    }

    local xml = xmlparse(source)

    utils.print_xml_element(xml.root)

    svg.draw_function = assert(loadstring(svg.draw_function))

    return svg
end

return svgparse

local utils = {}

function utils.print_xml_element(element, lvl)
    if lvl == nil then lvl = 0 end

    local indent = string.rep("  ", lvl)

    -- empty element
    if element.children == nil then
        print(indent .. "<" .. element.name .. "/>")

    -- regular element
    else
        print(indent .. "<" .. element.name .. ">")

        for _, v in ipairs(element.children) do
            utils.print_xml_element(v, lvl + 1)
        end

        print(indent .. "</" .. element.name .. ">")
    end
end

return utils

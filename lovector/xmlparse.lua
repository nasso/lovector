local function _attributes(attributes)
    return {}
end

local function _element(name, attributes, children)
    return {
        parent = nil;
        name = name;
        attributes = attributes;
        children = children;
    }
end

local function xmlparse(source)
    local xml = {
        root = _element("document", nil, {})
    }

    local current_parent = xml.root

    for tag, closes, name, attributes, empty in source:gmatch("(<(/?)([:A-Z_a-z][:A-Z_a-z0-9%-%.]*)(.-)(/?)>)") do
        closes = closes == "/"
        empty = empty == "/"

        if not closes then
            local element = _element(name, _attributes(attributes))
            element.parent = current_parent

            table.insert(current_parent.children, element)

            if not empty then
                element.children = {}
                current_parent = element
            end
        else
            current_parent = current_parent.parent
        end
    end

    return xml
end

return xmlparse

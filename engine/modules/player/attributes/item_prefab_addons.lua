local components_ = require("player.attributes.components")
local declarations = require("core.composer.declarations")

local operation_symbols = {
    ["+"] = "plus",
    ["-"] = "minus",
    ["*"] = "multiply",
    ["/"] = "divide"
}

return declarations.multiple { ---@type ItemPrefabAddon[]
    {
        id = "held_attributes",
        handle = function(context, document, components)
            local held_attributes = document["held_attributes"] ---@type table<string, string>
            if not held_attributes then return end

            local component = {}
            for attribute, modifier in pairs(held_attributes) do
                local operation_symbol = string.sub(modifier, 1, 1)
                local operation = operation_symbols[operation_symbol]
                if not operation then
                    context.report_error("Не удалось определить тип операции атрибута " ..
                        attribute .. ": " .. operation_symbol)
                    goto continue
                end

                local modifier = {
                    operation = operation,
                    value = tonumber(string.sub(modifier, 2, #modifier))
                }

                component[attribute] = modifier

                ::continue::
            end

            if next(component) ~= nil then
                table.insert(components, { type = components_.held_modifier, value = component })
            end
        end
    }
}

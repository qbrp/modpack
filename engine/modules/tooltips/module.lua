local declarations = require("core.composer.declarations")
local components = require("core.components")

local tooltips = {
    { kg = 0, text = "<green>Лёгкий" },
    { kg = 1, text = "<yellow>Ощутимый вес (~1 килограмм)" },
    { kg = 3, text = "<yellow>Увесистый (~3 килограмма)" },
    { kg = 5, text = "<gold>Тяжёлый (~5 килограмм)" },
    { kg = 10, text = "<gold>Тяжёлый (~10 килограмм)" },
    { kg = 20, text = "<red>Очень тяжёлый (от 20 килограмм)" },
    { kg = 45, text = "<red>Почти неподъемный (от 45 килограмм)" },
    { kg = 80, text = "<red>Неподъемный (от 80 килограмм)" },
}

return declarations.various {
    listeners = { ---@type EventListeners[]
        {
            show_item_tooltip = function(context)
                local mass = context.item:get_component(components.mass)
                if mass then
                    local current_tooltip
                    for _, tooltip in ipairs(tooltips) do
                        if mass.kg >= tooltip.kg then
                            current_tooltip = tooltip.text
                        else
                            break
                        end
                    end
                    return { current_tooltip }
                end
            end
        }
    }
}

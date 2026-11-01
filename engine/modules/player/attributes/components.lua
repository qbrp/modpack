local declarations = require("core.composer.declarations")
local components = require("core.composer.components")

---@alias AttributeOperation
---|"plus"
---|"minus"
---|"multiply"
---|"divide"

---@class Modifier
---@field operation AttributeOperation
---@field value number
---@class HeldAttributeModifierComponent : table<string, Modifier>
---@type ComponentTypeHolder<HeldAttributeModifierComponent>
local held_attribute_modifier = components.definition {
    id = "held_attribute_modifier",
    persistent = true,
    replicating = true
}

return declarations.multiple {
    held_modifier = held_attribute_modifier
}

local builtin_components = require("core.components")
local components = require("player.attributes.components")

local operations = {
    plus = function(original, value)
        return original + value
    end,
    minus = function(original, value)
        return original - value
    end,
    multiply = function(original, value)
        return original * value
    end,
    divide = function(original, value)
        return original / value
    end,
}

---@param base number
---@param modifiers Modifier[]?
---@return number
local modify_attribute = function(base, modifiers)
    local modifiers = modifiers or {}
    local computed = base
    for _, modifier in ipairs(modifiers) do
        local change = assert(operations[modifier.operation])
        computed = change(computed, modifier.value)
    end
    return computed
end

---@param player Entity
---@return table<string, Modifier[]>
local modifiers = function(player)
    local inventory = player:require_component(builtin_components.player_inventory)
    local held_items = {}

    if inventory.main_hand_item then table.insert(held_items, inventory.main_hand_item) end
    if inventory.off_hand_item then table.insert(held_items, inventory.off_hand_item) end

    local all_modifiers = {}
    for _, held_item in ipairs(held_items) do
        if not held_item then goto continue end
        local held_modifiers = held_item:get_component(components.held_modifier)
        if held_modifiers then
            for attribute, modifier in pairs(held_modifiers) do
                local modifiers_list = table.get_or_put(all_modifiers, attribute)
                table.insert(modifiers_list, modifier)
            end
        end
        ::continue::
    end

    return all_modifiers
end

return {
    modifiers = modifiers,
    modify_attribute = modify_attribute
}
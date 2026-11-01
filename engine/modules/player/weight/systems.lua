local declarations = require("core.composer.declarations")
local components = require("core.components")

---@type SystemDraft
local system = {
    id = "inventory_mass",
    query = { components.player, components.player_inventory, components.mass },
    side = "both",
    ---@param inventory PlayerInventoryComponent
    ---@param player_mass MassComponent
    tick = function (world, player, _, inventory, player_mass)
        local nominal_mass = 65.0
    
        local mass = nominal_mass
        for i = 1, #inventory.items do
            local item = assert(inventory.items[i])
            local item_mass = item:get_component(components.mass)
            if item_mass then
                mass = mass + item_mass.kg        
            end
        end

        player_mass.kg = mass
    end
}

return declarations.single(system)

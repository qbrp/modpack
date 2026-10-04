local declartions = require("core.composer.declarations")
local components = require("core.composer.components")

local components = {
    ---@alias NoclipEnabledComponent boolean
    ---@type ComponentTypeDefinition<NoclipEnabledComponent>
    enabled = components.definition {
        id = "enabled"
    }
}

return declartions.various {
    components = components,
    ---@type OperationDraft[]
    operations = {
        {
            id = "noclip",
            execute = function (context)
                local player = context.actor.player
                local enabled = player:get_component(components.enabled)
                if not enabled then
                    player:set_component(components.enabled, true)
                    context.feedback("Noclip включен")
                else
                    player:set_component(components.enabled, false)
                    context.feedback("Noclip выключен")
                end
            end
        }
    }
}
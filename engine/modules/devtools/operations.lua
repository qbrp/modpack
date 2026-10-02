local declarations = require("core.composer.declarations")

return declarations.single
---@type OperationDraft
{
    id = "inspect",
    execute = function (context)
        local player = context.actor.player
        local components = require("core.components")
        if not player then
            context.feedback("Операция вызывается только игроком")
            return
        end
        local item = assert(player:get_component(components.player_inventory)).main_hand_item
        if not item then
            context.feedback("В руке игрока нет предмета")
            return
        end
        local output = {}
        for type, component in pairs(item:list_components(true)) do
            local type_str = type.id
            output[type_str] = component
        end

        context.feedback(table.tostring_deep(output, true))
    end,
    permission = true
}

local declarations = require("core.composer.declarations")
local components = require("core.composer.components")

---@class OutfitComponent
---@field slot Id
---@type ComponentTypeHolder<OutfitComponent>
local outfit = components.definition {
    id = "outfit",
    persistent = true,
    replicating = true
}

---@type ComponentTypeDefinition<boolean>
local equip_command = components.definition { id = "equip_command" }

components = require("core.components")
local equippable = components.equippable

---@type Verb
local equip_verb = {
    id = "equip",
    name = "Экипировать",
    input_action = "base",
    priority = 15,
    create_command = function() return true end,
    command_type = equip_command
}

return declarations.various {
    components = {
        equip_command = equip_command,
        outfit = outfit
    },
    ---@type EventListeners[]
    listeners = {
        {
            show_item_tooltip = function(context)
                local item = context.item
                local outfit = item:get_component(outfit)
                local equippable = item:get_component(components.equippable)
                if outfit and equippable then
                    return { "<aqua>Экипируемый" }
                end
            end
        }
    },
    ---@type OperationDraft[]
    operations = {
        {
            id = "unequip",
            name = "Снять экипировку",
            inputs = {
                {
                    id = "slot",
                    type = "selection",
                    ---@param context OperationInputResolutionContext
                    variants = function(context)
                        local player = context.actor.player
                        if not player then return end
                        local equipment = player:get_component(components.equipment)
                        if equipment then
                            local variants = {}
                            for key, value in pairs(equipment.slots:to_table()) do
                                table.insert(
                                    variants,
                                    { id = key.loc, value = key }
                                )
                            end
                            return variants
                        end
                    end
                }
            },
            execute = function(context)
                local player = context.actor.player
                if not player then return end
                local equipment = player:get_component(components.equipment)
                if not equipment then return end
                local world = context.world

                local unequip_slot = assert(context.inputs.slot)
                local unequipped_item = equipment.slots:remove(unequip_slot)
                player:mark_updated(components.equipment)

                if unequipped_item then
                    if not world.is_client then
                        world:emit(components.give_item, { player = player, item = unequipped_item })
                    end
                    local item_name = unequipped_item:get_component(components.item_name) or { text = "Предмет" }
                    player:narration {
                        message = "Снят " .. item_name.text,
                        time = 40,
                    }
                end
            end
        }
    },
    ---@type SystemDraft[]
    systems = {
        {
            id = "verb_lookup",
            phase = "verb_lookup",
            query = { components.verb_lookup, components.hand },
            side = "both",
            ---@param lookup VerbLookupComponent
            ---@param hand HandComponent
            tick = function(world, interactor, lookup, hand)
                for _, input_action in ipairs(lookup.input) do
                    if input_action.type == "base" and hand.item then
                        local equippable = hand.item:get_component(components.equippable)
                        if equippable then
                            table.insert(lookup.verbs, equip_verb)
                        end
                    end
                end
            end
        },
        {
            id = "interaction",
            query = { equip_command, components.hand },
            side = "both",
            ---@param equip boolean
            ---@param hand HandComponent
            tick = function(world, interactor, equip, hand)
                interactor:remove_component(equip_command)
                local item = hand.item
                local player_entity = hand.owner
                if not item or not player_entity then return end

                local equippable = item:get_component(components.equippable)
                local outfit = item:get_component(outfit)
                local player_component = player_entity:get_component(components.player)
                if not equippable or not outfit or not player_component then return end

                local player = player_component.object
                local equipment = assert(player_entity:get_component(components.equipment))
                local slots = equipment.slots
                local slot = outfit.slot

                if slots[slot] then
                    player:narration {
                        message = "На вас уже надета экипировка под слотом " .. slot.loc,
                        time = 70
                    }
                    return
                end

                slots[slot] = item
                item:set_component(components.decrement, 1)

                local item_name = item:get_component(components.item_name) or { text = "Предмет" }
                player:narration {
                    message = "Надет " .. item_name.text,
                    time = 60,
                }
                player_entity:mark_updated(components.equipment)
            end
        }
    },
    item_prefab_addons = { ---@type ItemPrefabAddon[]
        {
            id = "outfit",
            handle = function(context, document, components)
                local outfit_document = document.outfit
                if not outfit_document then
                    return
                end
                local slot_id, error = context.module:resolve_id(outfit_document.slot)
                if error then
                    context.report_error(error)
                end
                outfit_document.slot = slot_id
                table.insert(components, { value = outfit_document, type = outfit })
                table.insert(components, { value = true, type = equippable })
            end,
            validate = function(context, prefab, components)
                local outfit = components[outfit.id]
                if not outfit then return end
                if prefab.max_count > 1 then
                    context.report_error(
                        "Наличие компонента Outfit требует значения максимального размера стака в 1 ед.")
                end
            end
        }
    }
}

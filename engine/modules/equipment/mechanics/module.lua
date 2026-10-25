local declarations = require("core.composer.declarations")
local components = require("core.composer.components")

---@class SidedOutfitComponent : Component
---@field slot_right Id
---@field slot_left Id
---@type ComponentTypeHolder<SidedOutfitComponent>
local sided_outfit = components.definition {
    id = "sided_outfit",
    persistent = true,
    replicating = true
}

---@class OutfitComponent : Component
---@field slot Id
---@type ComponentTypeHolder<OutfitComponent>
local outfit = components.definition {
    id = "outfit",
    persistent = true,
    replicating = true,
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

---@param id Id
---@return EquipmentSlot?
local function resolve_equipment_slot(id)
    return engine.contents.equipment_slots[id]
end

return declarations.various {
    components = {
        equip_command = equip_command,
        outfit = outfit,
        arm_outfit = sided_outfit
    },
    ---@type EventListeners[]
    listeners = {
        {
            show_item_tooltip = function(context)
                local item = context.item
                if not item:has_component(components.equippable) then return end

                local outfit = item:get_component(outfit)
                local sided_outfit = item:get_component(sided_outfit)

                if outfit then
                    local slot = resolve_equipment_slot(outfit.slot) or {}
                    return { "<gray>Одевается как <aqua>" .. string.lowercase_first(slot.name or slot.id.full) }
                elseif sided_outfit then
                    local slot_r = resolve_equipment_slot(sided_outfit.slot_right) or {}
                    local slot_l = resolve_equipment_slot(sided_outfit.slot_left) or {}
                    return {
                        "<gray>Одевается как:" ,
                        "<gray>- <aqua>" .. (slot_r.name or slot_r.id.full) .. " <gray>(держа в правой руке)",
                        "<gray>- <aqua>" .. (slot_l.name or slot_l.id.full) .. " <gray>(держа в левой руке)"
                    }
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
                            for key, _ in pairs(equipment.slots:to_table()) do
                                local slot = resolve_equipment_slot(key) or {}
                                table.insert(
                                    variants,
                                    { id = slot.name or key.loc, value = slot }
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

                local unequip_slot = assert(context.inputs.slot) ---@type EquipmentSlot
                local unequipped_item = equipment.slots:remove(unequip_slot.id)
                player:mark_updated(components.equipment)

                if unequipped_item then
                    if not world.is_client then
                        world:emit(components.give_item, { player = player, item = unequipped_item })
                    end
                    local item_name = unequipped_item:get_component(components.item_name) or { text = "Предмет" }
                    player:narration {
                        message = "<aqua>Снят " .. item_name.text,
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
                local arm_outfit = item:get_component(sided_outfit)
                local player_component = player_entity:get_component(components.player)
                if not equippable or (not outfit and not arm_outfit) or not player_component then return end

                local player = player_component.object
                local equipment = assert(player_entity:get_component(components.equipment))
                local slots = equipment.slots

                local slot_id
                if outfit then
                    slot_id = outfit.slot
                elseif arm_outfit then
                    if hand.side == "main" then
                        slot_id = arm_outfit.slot_right
                    else
                        slot_id = arm_outfit.slot_left
                    end
                end
                local slot = resolve_equipment_slot(slot_id) or {}

                if slots[slot_id] then
                    player:narration {
                        message = "<gold>На вас уже надета экипировка под слотом " .. slot.name or slot_id.loc,
                        time = 70
                    }
                    return
                end

                slots[slot_id] = item
                item:set_component(components.decrement, 1)

                local item_name = item:get_component(components.item_name) or { text = "Предмет" }
                player:narration {
                    message = "<aqua>Надет " .. item_name.text,
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

                local function resolve_id_catching(slot_id)
                    local slot_id, error = context.module:resolve_id(slot_id)
                    if error then context.report_error(error) end
                    return slot_id
                end

                if outfit_document.sided then
                    local right_slot_id = resolve_id_catching(outfit_document.slot_right)
                    local left_slot_id = resolve_id_catching(outfit_document.slot_left)
                    if not right_slot_id or not left_slot_id then return end

                    local arm_outfit_component = {
                        slot_right = right_slot_id,
                        slot_left = left_slot_id
                    }

                    table.insert(components, { value = arm_outfit_component, type = sided_outfit })
                else
                    local slot_id = resolve_id_catching(outfit_document.slot)
                    if not slot_id then return end

                    local outfit_component = { slot = slot_id }
                    table.insert(components, { value = outfit_component, type = outfit })
                end

                table.insert(components, { value = true, type = equippable })
            end,
            validate = function(context, prefab, components)
                local outfit = components[outfit.id] or components[sided_outfit.id]
                if not outfit then return end
                if prefab.max_count > 1 then
                    context.report_error(
                        "Наличие компонента одежды требует значения максимального размера стака в 1 ед.")
                end
            end
        }
    }
}

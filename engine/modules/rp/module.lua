local components = require("core.components")
local declarations = require("core.composer.declarations")
local lazy = require("core.util.lazy")
local time = engine.time

local MSK = time.zone("Europe/Moscow")
local ANNOTATION_MAX_LENGTH = 200

---@class ItemAnnotationsComponent : Component
---@field annotations ItemAnnotation[]

---@class ItemAnnotation
---@field created_at Instant
---@field author string
---@field text string

---@type ComponentTypeHolder<ItemAnnotationsComponent>
local item_annotations = lazy.component_holder("rp/item_annotation")

---@param text string
---@return string? error
local function validate_annotation_text(text)
    local length = string.len(text)
    if length > ANNOTATION_MAX_LENGTH then
        return "Аннотация слишком длинная, максимальный размер - " ..
            ANNOTATION_MAX_LENGTH .. " символов (в данный момент " .. length .. ")"
    end
end

---@param item Entity
---@param author string
---@param text string
---@param index integer?
---@return integer
local function add_annotation(item, author, text, index)
    local component = item:get_component(item_annotations)
    if not component then
        component = item:set_component(item_annotations, { annotations = {} })
    end
    local pos = index or (#component.annotations + 1)
    table.insert(component.annotations, pos, {
        created_at = time.now(),
        author = author,
        text = text
    })
    item:mark_updated(item_annotations)
    return #component.annotations
end

---@param item Entity
---@param component ItemAnnotationsComponent
---@param index integer
local function remove_annotation(item, component, index)
    local annotations = component.annotations
    table.remove(annotations, index)
    if #annotations == 0 then
        item:remove_component(item_annotations)
    else
        item:mark_updated(item_annotations)
    end
end

---@param actor OperationActor
---@return Entity? item
---@return string? error
local function hand_item(actor)
    local player = actor.player
    if not player then
        return nil, "Операция вызывается только игроком"
    end
    local item = assert(player:get_component(components.player_inventory)).main_hand_item
    if not item then
        return nil, "В руке игрока нет предмета"
    end
    return item, nil
end

local item_annotation_variants = function(context)
    local item, error = hand_item(context.actor)
    if not item then return nil end
    local component = item:get_component(item_annotations)
    if not component then return nil end
    local result = {}
    for index, _ in ipairs(component.annotations) do
        table.insert(result, {
            id = tostring(index),
            value = index,
        })
    end
    return result
end

return declarations.various {
    ---@type EventListeners[]
    listeners = {
        {
            show_item_tooltip = function(context)
                local component = context.item:get_component(item_annotations)
                if not component then
                    return nil
                end

                local main_player = context.game_session.main_player
                local is_admin = main_player:get_component(components.player_mode).is_game_master
                local lines = {}

                for index, annotation in ipairs(component.annotations) do
                    local line
                    local author = annotation.author
                    local text = annotation.text
                    if is_admin then
                        local date = time.format(annotation.created_at:zoned(MSK), "dd MMMM, HH:mm", "ru")
                        line = string.format("<dark_gray>[%02d]</dark_gray> <gray>%s</gray> <dark_gray>(%s) (%s)", index,
                            text, author, date)
                    else
                        line = string.format("<dark_gray>[%02d]<dark_gray> <gray>%s</gray>", index, text)
                    end
                    lines[index] = line
                end

                return lines
            end
        }
    },
    ---@type ComponentTypeSettings[]
    components = {
        -- с version 1 добавлено поле created_at
        {
            id = "item_annotation",
            replicating = true,
            persistent = true,
            version = 1,
            migrations = {
                ---@param component ItemAnnotationsComponent
                function(component) -- версия 0
                    for _, annotation in ipairs(component.annotations) do
                        annotation.created_at = time.now()
                    end
                    return component
                end
            }
        }
    },
    ---@type OperationDraft[]
    operations = {
        {
            id = "annotate",
            inputs = {
                {
                    id = "text",
                    type = "text"
                }
            },
            execute = function(context)
                local text = context.inputs.text ---@type string
                local player = context.actor.player
                local item, error = hand_item(context.actor)
                if error then
                    context.feedback(error)
                    return
                end
                assert(item)
                local validation_error = validate_annotation_text(text)
                if validation_error then
                    context.feedback(validation_error)
                    return
                end
                local index = add_annotation(item, player.user_name, text)
                context.feedback("Аннотация добавлена под номером " .. index)
            end
        },
        {
            id = "removeannotation",
            inputs = {
                {
                    id = "index",
                    type = "selection",
                    variants = item_annotation_variants
                }
            },
            execute = function(context)
                local index = context.inputs.index
                local item, error = hand_item(context.actor)
                if error then
                    context.feedback(error)
                    return
                end
                assert(item)
                local component = item:get_component(item_annotations)
                if not component then
                    context.feedback("Предмет не имеет аннотаций")
                    return
                end

                remove_annotation(item, component, index)
                context.feedback("Аннотация под номером " .. index .. " убрана")
            end
        },
        {
            id = "replaceannotation",
            inputs = {
                {
                    id = "index",
                    type = "selection",
                    variants = item_annotation_variants
                },
                {
                    id = "text",
                    type = "text",
                }
            },
            execute = function(context)
                local index = context.inputs.index
                local text = context.inputs.text
                local player = context.actor.player
                local item, error = hand_item(context.actor)
                if error then
                    context.feedback(error)
                    return
                end
                assert(item)
                local component = item:get_component(item_annotations)
                if not component then
                    context.feedback("Предмет не имеет аннотаций")
                    return
                end

                local error = validate_annotation_text(text)
                if error then
                    context.feedback(error)
                    return
                end

                remove_annotation(item, component, index)
                add_annotation(item, player.user_name, text, index)
                context.feedback("Аннотация под номером " .. index .. " заменена")
            end
        },

        {
            id = "moveannotation",
            inputs = {
                {
                    id = "from",
                    type = "selection",
                    variants = item_annotation_variants
                },
                {
                    id = "to",
                    type = "selection",
                    variants = item_annotation_variants
                }
            },
            execute = function(context)
                local from = context.inputs.from
                local to = context.inputs.to

                local item, error = hand_item(context.actor)
                if error then
                    context.feedback(error)
                    return
                end
                assert(item)

                local component = item:get_component(item_annotations)
                if not component then
                    context.feedback("Предмет не имеет аннотаций")
                    return
                end

                if from == to then
                    context.feedback("Аннотация уже находится под номером " .. from)
                    return
                end

                local annotation = table.remove(component.annotations, from)
                table.insert(component.annotations, to, annotation)

                item:mark_updated(item_annotations)

                context.feedback(
                    "Аннотация перемещена с номера " .. from .. " на номер " .. to
                )
            end
        }

    }
}

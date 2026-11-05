local components = require("core.components")

local modify_attribute = require("player.attributes.api").modify_attribute
local modifiers = require("player.attributes.api").modifiers

local settings = require("player.movement.settings")
local declarations = require("core.composer.declarations")

return declarations.multiple { ---@type SystemDraft[]
    {
        id = "movement/application",
        query =  {
            components.movement_status,
            components.player_input,
            components.player_attributes,
            components.player_custom_attributes
        },
        side = "both",
        ---@param player Entity
        ---@param movement MovementStatusComponent
        ---@param input PlayerInputComponent
        ---@param attributes PlayerAttributesComponent
        ---@param customs PlayerCustomAttributesComponent
        tick = function(world, player, movement, input, attributes, customs)
            local mode = player:require_component(components.player_mode)
            local mass = player:require_component(components.mass)

            local previous_speed = attributes.speed
            local previous_jump_strength = attributes.jump_strength
            local primary_attributes = settings.get_primary_attributes(mode.mode)
            local default_speed = customs.speed or primary_attributes.speed
            local modifiers = modifiers(player)

            if movement.stamina < settings.jump_stamina_consume or (input.is_sprinting and not mode.is_game_master) then
                attributes.jump_strength = 0
            else
                attributes.jump_strength = modify_attribute(primary_attributes.jump_strength, modifiers.jump_strength)
            end

            if mode.is_spectator then
                attributes.speed = default_speed
                if attributes.speed ~= previous_speed
                    or attributes.jump_strength ~= previous_jump_strength then
                    player:mark_updated(components.player_attributes)
                end
                return
            end

            local ignore_physics = mode.is_game_master or mode.is_spectator
            local max_speed = default_speed * settings.speed_multiplier(1, 1, true, mass.kg, ignore_physics, settings)
            local min_speed = math.min(default_speed * settings.min_speed_factor, max_speed)

            local target = math.clamp(
                default_speed
                * settings.speed_multiplier(
                    movement.intention,
                    movement.stamina,
                    input.is_sprinting,
                    mass.kg,
                    ignore_physics,
                    settings
                ),
                min_speed,
                max_speed
            )

            attributes.speed = math.lerp(
                attributes.speed,
                modify_attribute(target, modifiers.speed),
                0.2
            )

            if attributes.speed ~= previous_speed
                or attributes.jump_strength ~= previous_jump_strength then
                player:mark_updated(components.player_attributes)
            end
        end
    },
    {
        id = "movement/stamina_consumption",
        after = "movement/application",
        query = { components.movement_status, components.player_mode, components.player_velocity, components.player_input },
        side = "both",
        ---@param entity Entity
        ---@param movement MovementStatusComponent
        ---@param mode PlayerModeComponent
        ---@param velocity PlayerVelocityComponent
        ---@param input PlayerInputComponent
        tick = function(_, entity, movement, mode, velocity, input)
            local jumped = entity:remove_component(components.jump) ~= nil

            if mode.is_spectator then return end

            if mode.is_game_master then
                if movement.stamina ~= 1 then
                    movement.stamina = 1
                    entity:mark_updated(components.movement_status)
                end
                return
            end

            local stamina_regen = 0
            local sprint_multiplier = 1.0
            local movement_consumption = 0.0
            
            if input.is_sprinting then
                sprint_multiplier = settings.stamina_consumption_sprint_multiplier
            end
            
            local motion = velocity.motion
            local moving = math.sqrt(motion.x * motion.x + motion.z * motion.z) > 0.0001
            if moving then
                movement_consumption = movement.intention * sprint_multiplier * settings.stamina_consumption
                stamina_regen = settings.stamina_regen_on_move
            else
                stamina_regen = settings.stamina_regen
            end

            local jump_consumption = jumped and settings.jump_stamina_consume or 0
            local stamina = math.clamp(
                movement.stamina
                    + stamina_regen
                    - movement_consumption
                    - jump_consumption,
                0,
                1
            )
            if stamina ~= movement.stamina then
                movement.stamina = stamina
                entity:mark_updated(components.movement_status)
            end
        end
    }
}

local components = require("core.components")
local settings = require("player.movement.settings")
local declarations = require("core.composer.declarations")

return declarations.multiple { ---@type SystemDraft[]
    {
        id = "movement/speed_application",
        query =  {
            components.movement_status,
            components.player_mode,
            components.player_input,
            components.player_attributes,
            components.player_custom_attributes
        },
        side = "both",
        ---@param movement MovementStatusComponent
        ---@param mode PlayerModeComponent
        ---@param input PlayerInputComponent
        ---@param attributes PlayerAttributesComponent
        ---@param customs PlayerCustomAttributesComponent
        tick = function(player, _, movement, mode, input, attributes, customs)
            local primary_attributes = settings.get_primary_attributes(mode.mode)
            local default_speed = customs.speed or primary_attributes.speed

            if movement.stamina > settings.jump_stamina_consume then
                attributes.jump_strength = primary_attributes.jump_strength
            else
                attributes.jump_strength = 0
            end

            -- local inventory = player:get_component(components.player_inventory)
            -- if inventory and inventory.main_hand_item then
            --     local item = inventory.main_hand_item
                
            --     if item_speed then
            --         default_speed = default_speed * item_speed.multiplier
            --     end
            -- end

            if mode.is_spectator then
                attributes.speed = default_speed
                return
            end

            local max_speed = default_speed * settings.speed_multiplier(1, 1, true, settings)
            local min_speed = math.min(default_speed * settings.min_speed_factor, max_speed)
            local target = math.clamp(
                default_speed
                * settings.speed_multiplier(
                    movement.intention,
                    movement.stamina,
                    input.is_sprinting,
                    settings
                ),
                min_speed,
                max_speed
            )

            attributes.speed = math.lerp(attributes.speed, target, 0.2)
        end
    },
    {
        id = "movement/stamina_consumption",
        after = "movement/speed_application",
        query = { components.movement_status, components.player_mode, components.player_velocity },
        side = "both",
        ---@param entity Entity
        ---@param movement MovementStatusComponent
        ---@param mode PlayerModeComponent
        ---@param velocity PlayerVelocityComponent
        tick = function(_, entity, movement, mode, velocity)
            local jumped = entity:remove_component(components.jump) ~= nil

            if mode.is_spectator then return end

            if mode.is_game_master then
                movement.stamina = 1
                return
            end

            local primary_attributes = settings.get_primary_attributes(mode.mode)
            local max_speed = primary_attributes.speed * settings.speed_multiplier(1, 1, true, settings)
            local motion = velocity.motion
            local horizontal_speed = math.sqrt(motion.x * motion.x + motion.z * motion.z)

            local movement_consumption = 0.0
            if max_speed > 0 then
                movement_consumption =
                    math.abs(horizontal_speed) / max_speed * settings.stamina_consumption
            end

            local jump_consumption = jumped and settings.jump_stamina_consume or 0

            movement.stamina = math.clamp(
                movement.stamina
                    + settings.stamina_regen
                    - movement_consumption
                    - jump_consumption,
                0,
                1
            )
        end
    }
}

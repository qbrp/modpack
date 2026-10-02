---@class MovementPrimaryAttributes
---@field speed number
---@field jump_strength number

---@class MovementSettings
local movement_settings = {
    sprint_multiplier = 1.3,
    min_speed_factor = 0.05,
    slowdown_stamina_threshold = 0.3,
    stamina_consumption = 0.0033,
    stamina_regen = 0.003,
    sprint_min_intention_effect = 0.5,
    intention_effect = 0.7,
    jump_stamina_consume = 0.1,
    ---@type table<PlayerMode, MovementPrimaryAttributes>
    primary_attributes = {
        default = { speed = 0.13, jump_strength = 0.4 },
        gm = { speed = 0.12, jump_strength = 0.45 },
        spectator = { speed = 0.15, jump_strength = 0.55 }
    }
}

---@param intention number
---@param stamina number
---@param is_sprinting boolean
---@param settings MovementSettings
function movement_settings.speed_multiplier(intention, stamina, is_sprinting, settings)
    local sprint_multiplier = 1.0
    local min_speed_addition = 0.0
    if is_sprinting then
        sprint_multiplier = settings.sprint_multiplier
        min_speed_addition = settings.sprint_min_intention_effect
    end

    local stamina_multiplier = 1.0
    if stamina < settings.slowdown_stamina_threshold then
        stamina_multiplier = math.smoothstep(stamina / settings.slowdown_stamina_threshold)
    end

    local min_intention_multiplier = 1 - settings.intention_effect + min_speed_addition
    local max_intention_multiplier = settings.intention_effect * 2 - 1
    local intention_multiplier = min_intention_multiplier
        + max_intention_multiplier * math.smootherstep(intention)
    return intention_multiplier * stamina_multiplier * sprint_multiplier
end

---@param mode PlayerMode
---@return MovementPrimaryAttributes
function movement_settings.get_primary_attributes(mode)
    return assert(
        movement_settings.primary_attributes[mode] or movement_settings.primary_attributes["default"]
    )
end

return movement_settings

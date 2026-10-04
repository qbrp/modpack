local components = require("core.components")
local declarations = require("core.composer.declarations")
local no_clip = require("player.noclip").components

return declarations.various {
    ---@type SystemDraft[]
    systems = {
        {
            id = "spectating/no_clip",
            query = { components.player_mode, components.player_physics },
            side = "both",
            ---@param player_mode PlayerModeComponent
            ---@param player_physics PlayerPhysicsComponent
            tick = function(_, player, player_mode, player_physics)
                local noclip_enabled = player:get_component(no_clip.enabled) == true
                player_physics.no_clip = player_mode.is_spectator or noclip_enabled
            end
        }
    }
}

local components = require("core.components")
local declarations = require("core.composer.declarations")

return declarations.multiple { ---@type SystemDraft[]
    {
        id = "spectating/no_clip",
        query = { components.player_mode, components.player_physics },
        side = "both",
        ---@param player_mode PlayerModeComponent
        ---@param player_physics PlayerPhysicsComponent
        tick = function (world, entity, player_mode, player_physics)
            player_physics.no_clip = player_mode.is_spectator
        end
    }
}

---@class SpectatorBlockComponent : Component
---@field blocked boolean
SpectatorBlockComponent = Component.of("qbrp/spectator_block")

---@return SpectatorBlockComponent
function SpectatorBlockComponent.new()
    return SpectatorBlockComponent:construct({ blocked = false })
end

---@param player Player
---@param world World
local function SpectatorFreezeSystem(world, player)
    if (world.is_client) then return end
    if (player.is_spectating) then
        local spectator_block = player.entity:get_or_create_component(SpectatorBlockComponent, function() return SpectatorBlockComponent.new() end)
        if (player:has_permission("dont_freeze_spectator")) then
            if spectator_block.blocked == false then
                player:narration("Свободное перемещение в режиме наблюдателя запрещено! Вселитесь в кого-нибудь.", 200)
                spectator_block.blocked = true
                --player.entity:mark_dirty(SpectatorBlockComponent)
            end
        else
            if (spectator_block.blocked == true) then
                spectator_block.blocked = false
                --player.entity:mark_dirty(SpectatorBlockComponent)
            end
        end
    end
end

---@param player Player
---@param world World
---@param component SpectatorBlockComponent
local function SpectatorBlockMoveSystem(world, component, player)
    if (component.blocked) then
        player:set_flying_speed(0)
        if (world.is_client) then
            Keys.get_key_mapping("key.sneak").enabled = false
        end
    else
        if (world.is_client) then
            Keys.get_key_mapping("key.sneak").enabled = true
        end
    end
    player:set_flying_speed(1)
end
--
--Callbacks.build()
--         :player_system({ }, SpectatorFreezeSystem)
--         --:player_system({ SpectatorBlockComponent }, SpectatorBlockMoveSystem)
--         :submit()

compilation(function()
    local result = CompilationResult.new()
    result:namespace {
        id = "qbrp",
        components = ComponentList {
            { id = "spectator_block", networking = true }
        },
    }
    return result
end)
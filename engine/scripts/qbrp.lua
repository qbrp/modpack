require("core.util")
require("core.world")
require("core.registration")
require("core.player")
require("core.component")
require("core.audio")
require("core.light")
require("server.items")
require("server.spectator_freeze")
require("server.subterrina")

reload("core")

---@param context InteractionScriptContext
local function FreezePlayerScript(context)
    if (context.player:is_game_master()) then return end
    context.raycast_player:narration("Вас остановил ГМ, успокойтесь", seconds(5), true)
    context.raycast_player:freeze(seconds(5))
end

---@class LockComponent : Component
LockComponent = Component.of("gm_scripts/lock")

---@param context VoxelActionScriptContext
local function on_place_voxel(context)
    local voxel_meta = context.voxel_meta
    local world = context.world
    local pos = context.voxel_pos

    if (voxel_meta.has_tag("doors")) then
        local entity = world:set_dynamic_voxel(pos)
        local entity2_pos = { pos[1], pos[2] + 1, pos[3] }
        local entity2 = world:set_dynamic_voxel(entity2_pos)
        entity:set_component(LockComponent:construct())
        entity2:set_component(LockComponent:construct())
    end
end

---@param world World
---@param entity Entity
local function LockSystem(world, entity, lock)
    if (not entity:has_component(UseRestrictionComponent)) then
        entity:set_component(Component.construct(UseRestrictionComponent, {}))
    end
end

---@param context IntentScriptContext
local function AlarmScript(context)
    if (not context.world.is_client) then return end
    local target = context.gen_target()
    local entity = context.world:add_sound_entity("sounds/engine", { pos = target.pos, attenuate = true })
    entity:set_component(RepeatableComponent.new(context.inputs.repeats))
end

---@param context IntentScriptContext
local function LightBlockScript(context)
    local world = context.world
    if (world.is_client) then return end
    local inputs = context.inputs
    local target = context.gen_target()
    local voxel = world:set_dynamic_voxel(target.voxel_pos, true)

    local light_source = LightSourceBehaviour.sphere(8)
    local flash = FlashingComponent.new(inputs.pattern, inputs.min, inputs.max)

    voxel:set_light_entity(light_source, 14, target.pos)
    voxel:set_component(flash)
end

local alarm = Script.new("alarm", AlarmScript)
local freeze_player = Script.new("freeze_player", FreezePlayerScript)
local light_block = Script.new("light_block", LightBlockScript)

compilation(function()
    local result = CompilationResult.new()
    result:namespace {
        id = "gm_scripts",
        scripts = { alarm, freeze_player, light_block },
        components = ComponentList { "lock" },
        intents = {
            Intent.of(
                    "alarm",
                    "gm_scripts/alarm",
                    true,
                    "Воксельная алярма",
                    { IntentInput.of("repeats", "double") }
            ),
            Intent.of(
                    "light_block",
                    "gm_scripts/light_block",
                    true,
                    "Подсветить",
                    { IntentInput.of("pattern", "text"), IntentInput.of("min", "double"), IntentInput.of("max", "double") }
            )
        },
    }
    compile_items(result)
    compile_subterrina(result)
    return result
end)

Callbacks.build()
         :on_place_voxel(on_place_voxel)
         :system({ LockComponent }, LockSystem)
         :submit()
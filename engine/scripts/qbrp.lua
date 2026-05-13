require("core.util")
require("core.world")
require("core.registration")
require("core.player")
require("core.component")
require("core.audio")
require("core.light")
require("server.items")

reload("core")

---@param context InteractionScriptContext
local function FreezePlayerScript(context)
    if (context.player:is_game_master()) then return end
    context.raycast_player:narration("Вас остановил ГМ, успокойтесь", seconds(5), true)
    context.raycast_player:freeze(seconds(5))
end

---@param context IntentScriptContext
local function AlarmScript(context)
    if (not context.world.is_client) then return end
    local target = context.gen_target()
    local entity = context.world:add_sound_entity("sounds/klaxon", { pos = target.pos, attenuate = true })
    entity:set_component(RepeatableComponent.new(5))
end

---@param context IntentScriptContext
local function LightBlockScript(context)
    local world = context.world
    if (world.is_client) then return end
    local target = context.gen_target()
    local voxel = world:set_dynamic_voxel(target.pos, true)
    world:set_light_entity(LightSourceBehaviour.sphere(8), 14, target.pos, voxel)
    voxel:set_component(FlashingComponent.new("aooaoaoaooaaaoooooooaoaoaoooaa", 0, 14))
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
            Intent.of("gm_scripts/alarm", "Воксельная алярма"),
            Intent.of("gm_scripts/light_block", "Подсветить")
        },
    }
    compile_items(result)
    return result
end)

Callbacks.build()
         :submit()
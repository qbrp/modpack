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
require("server.gm_scripts")

reload("core")

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

local light_block = Script.new("light_block", LightBlockScript)

compilation(function()
    local result = CompilationResult.new()
    result:namespace {
        id = "lights",
        scripts = { light_block },
        intents = {
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
    compile_gm_scripts(result)
    return result
end)

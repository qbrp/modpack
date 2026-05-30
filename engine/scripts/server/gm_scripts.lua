---@param context InteractionScriptContext
local function FreezePlayerScript(context)
    if (context.player:is_game_master()) then return end
    context.raycast_player:narration("Вас остановил ГМ, успокойтесь", seconds(5), true)
    context.raycast_player:freeze(seconds(5))
end

local freeze_player = Script.new("freeze_player", FreezePlayerScript)

---@param result CompilationResult
function compile_gm_scripts(result)
    result:namespace {
        id = "gm_scripts",
        scripts = { freeze_player }
    }
end
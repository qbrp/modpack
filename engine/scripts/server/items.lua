require("server.funny")
require("server.bodies")

---@param result CompilationResult
function compile_items(result)
    compile_items_funny(result)
    compile_items_bodies(result)
end
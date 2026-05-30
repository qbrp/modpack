require("server.funny")
require("server.bodies")
require("server.food")

---@param result CompilationResult
function compile_items(result)
    compile_items_funny(result)
    compile_items_bodies(result)
    compile_items_food(result)
end
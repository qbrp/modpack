require("core.registration")

---@param result CompilationResult
function compile_items_bodies(result)
    local civil = Namespace.of("bodies/civil")
    civil.items = {
        civil:item("bum", "Спящий бездомный", { tooltip = "Бом, проснись" })
    }
    result:namespace(civil)

    local other = Namespace.of("bodies/other")
    other.items = {
        other:item("pigeon", "Ворона")
    }
    result:namespace(other)
end
require("core.registration")

---@return Item
function Namespace:dakimakura(id, name)
    return self:item(
    "dakimakura_" .. id,
    "Дакимакура " .. name,
    { asset = self.id .. "/dakimakura/" .. id })
end

---@param result CompilationResult
function compile_items_funny(result)
    local funny = Namespace.of("funny")
    funny.items = {
        funny:dakimakura("arestovich", "Арестович"),
        funny:dakimakura("dora", "Дора"),
        funny:dakimakura("shariy", "Шарий"),
        funny:item("guitar", "Акустическая гитара")
    }
    result:namespace(funny)
end
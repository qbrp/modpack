require("core.registration")

---@type Namespace for EmmyLua
local Namespace = Namespace

---@param result CompilationResult
function compile_items_food(result)
    --- создаём пустое пространство имён с id "bodies/civil" и записываем его в переменную civil
    --- функция создания пространства имён (называется of) хранится в глобальной таблице Namespace
    local food = Namespace.of("food")
    local spam_description = [[Продукт мясосодержащий, /"Гыча"/.]]
    local concentrate_description = [[Концентрат, зелёный, 30 проба.]]

    food.items = {
        food:item("can_beans", "Консервированные бобы", { tooltip = "Бобы знакомой вам марки, открывашка отсутсвует.", mass = 0.3 }),
        food:item("can_meat", "Консервированное тушёное мясо", { tooltip = "Тушёнка, открывашка отсутсвует.", mass = 0.4 }),
        food:item("can_fish", "Консервированная рыба", { tooltip = "Рыба, готовая к употреблению.", mass = 0.4 }),
        food:item("spam", "Продукт консервированный \"Гыча\"", { tooltip = spam_description, mass = 0.35 }),
        food:item("canned_water", "Консервированная вода", { tooltip = "Стратегический запас Санации, лучше воды вы не пробовали.", mass = 0.35 }),
        food:item("edrink", "Энергетический напиток", { tooltip = "Напиток массового производства, от рогулей до армии.", mass = 0.2 }),
        food:item("beer", "Бутилированное пиво", { tooltip = "Самый распостранный алкогольный напиток во Фрактале.", mass = 0.8 }),
        food:item("bottle", "Бутилированная вода", { tooltip = "Пластиковая бутылка воды", mass = 1 }),
        food:item("concentrate", "Концентрат пищевой", { tooltip = concentrate_description, mass = 0.25 }),
        food:item("pills", "Банка таблеток", { mass = 0.1 })
    }
    result:namespace(food)
end
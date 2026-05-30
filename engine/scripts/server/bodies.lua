require("core.registration")

---@type Namespace for EmmyLua
local Namespace = Namespace

---@return Item
function Namespace:add_corpses_ruined(type, postfix)
    --- функция автоматически составляет название предмета
    local name = "Уничтоженный труп " .. postfix
    --- проверяет, есть ли в пространстве имён список предметов (self.items)
    --- если списка предметов нет - создаёт его (пустой список)
    self.items = self.items or {}
    --- вставляет в список предметов с помощью функции table предмет, возвращаемый функцией item
    table.insert(self.items, self:item("corpse_" .. type .. "_ruined1", name))
    table.insert(self.items, self:item("corpse_" .. type .. "_ruined2", name))
    --- конкретно в данном случае функция добавляет в список предметов сразу два трупа, с разными айдишникам
end

---@param result CompilationResult
function compile_items_bodies(result)
    --- создаём пустое пространство имён с id "bodies/civil" и записываем его в переменную civil
    --- функция создания пространства имён (называется of) хранится в глобальной таблице Namespace
    local civil = Namespace.of("bodies/civil")

    --- устанавливаем значение переменной просранства имён items на список
    --- в список прокидывается возвращаемая функцией item результат
    civil.items = {
        civil:item("bum", "Спящий бездомный", { tooltip = "Бом, проснись" })
    }

    local other = Namespace.of("bodies/other")
    other.items = {
        other:item("pigeon", "Ворона")
    }

    local ruined = Namespace.of("bodies/ruined")
    --- вызываем для пространства имён ruined собственную функцию add_corpse_ruined
    ruined:add_corpses_ruined("hanging_down", "свисающий")
    ruined:add_corpses_ruined("lying", "лежащий")
    ruined:add_corpses_ruined("lying2", "лежащий")
    ruined:add_corpses_ruined("sitting", "сидящий")

    local untouched = Namespace.of("bodies/untouched")
    untouched.items = {
        untouched:item("pstfs_corpse_hanging_down", "Свисающий труп солдата ВС Постфедерации"),
        untouched:item("pstfs_corpse_lying", "Лежащий труп солдата ВС Постфедерации"),
        untouched:item("pstfs_corpse_lying2", "Лежащий труп солдата ВС Постфедерации"),
        untouched:item("pstfs_corpse_sitting", "Сидящий труп солдата ВС Постфедерации")
    }

    --- добавляем в результат компиляции созданные пространства имён
    result:namespace(untouched)
    result:namespace(ruined)
    result:namespace(civil)
    result:namespace(other)
end
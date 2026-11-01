local id_migrations = require("core.migration.id")
local id = engine.id

---@param namespace string
---@param item_id string
---@param new_namespace string?
---@return IdMigration
local function from_environment_to(namespace, item_id, new_namespace)
    return {
        from = id.new("environment/" .. namespace, item_id),
        to = id.new(new_namespace or namespace, item_id)
    }
end

---@param namespace string
---@param item_id string
---@param new_namespace string?
---@return IdMigration
local function from_survival_to(namespace, item_id, new_namespace)
    return {
        from = id.new("survival/" .. namespace, item_id),
        to = id.new(new_namespace or namespace, item_id)
    }
end

---@param namespace string
---@param item_id string
---@param new_item_id string?
---@return IdMigration
local function equipment_from_clothing_to(namespace, item_id, new_item_id)
    return {
        from = id.new("equipment/clothing", item_id),
        to = id.new("equipment/" .. namespace, new_item_id or item_id)
    }
end

---@type ComposerPlugin
return {
    name = "Item migrations",
    append_listeners = function (context)
        local migrations = { ---@type IdMigration[]
            from_environment_to("meta", "glesgorv_model"),
            from_environment_to("meta", "coil_aqua"),
            from_environment_to("meta", "error"),
            from_environment_to("meta", "blyat"),
            from_environment_to("meta", "uebanity"),

            {
                from = id.parse("environment/decorative/sign/flag_holder"),
                to = id.parse("environment/decorative/sign/flag_holder_sanation")
            },
            
            from_survival_to("food", "can_beans", "kitchen"),
            from_survival_to("food", "can_meat", "kitchen"),
            from_survival_to("food", "can_fish", "kitchen"),
            from_survival_to("food", "can_spam", "kitchen"),
            from_survival_to("food", "can_water", "kitchen"),
            from_survival_to("food", "energy_drink", "kitchen"),
            from_survival_to("food", "bottle", "kitchen"),
            from_survival_to("food", "concentrate", "kitchen"),
            from_survival_to("food", "beer", "kitchen"),

            from_survival_to("food/meat", "piece_rotten", "kitchen/meat"),
            from_survival_to("food/meat", "piece_raw", "kitchen/meat"),
            from_survival_to("food/meat", "piece_cooked", "kitchen/meat"),
            from_survival_to("food/meat", "pile_rotten_guts", "kitchen/meat"),
            from_survival_to("food/meat", "pile_raw_guts", "kitchen/meat"),

            {
                from = id.parse("kitchen/concentrate"),
                to = id.parse("kitchen/concentrates/legacy")
            },

            equipment_from_clothing_to("glasses", "aviator_eyewear", "aviator"),
            equipment_from_clothing_to("glasses", "ballistic_eyewear", "ballistic"),
            equipment_from_clothing_to("glasses", "vision_eyewear", "vision"),

            equipment_from_clothing_to("military", "nvg"),
            equipment_from_clothing_to("military", "cws_bulletproof", "plate_bodyarmor"),
            equipment_from_clothing_to("military", "cws_pouche", "bodyarmor_pouches"),
            equipment_from_clothing_to("military", "helmet_glasses"),
            equipment_from_clothing_to("military", "helmet_fast_mt"),
            equipment_from_clothing_to("military", "helmet_stuff_fast"),
            equipment_from_clothing_to("military", "supply_rig"),
            equipment_from_clothing_to("military", "container_carrier"),
            equipment_from_clothing_to("military", "security_vest_black"),
            equipment_from_clothing_to("military", "gsh01"),
        }

        return { id_migrations.events(context, migrations) }
    end
}
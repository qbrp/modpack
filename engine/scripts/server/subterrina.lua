---@type World for EmmyLua
local World = World

---@class SoundEntity
---@field entity Entity
---@field sound SoundComponent

---@param entity Entity
---@param sound SoundComponent
---@return SoundEntity
local function sound_entity_of(entity, sound)
    return { entity = entity, sound = sound }
end

------------------

---@param world World
---@param voxel DynamicVoxelComponent
---@param reactor SubterrinaReactorComponent
local function SubterrinaReactorSoundSystem(world, entity, voxel, reactor)
    if reactor.sound == nil and reactor.phase ~= "disabled" then
        local reactor_ambience, e = world:add_sound_entity(
            "sounds/ambience-reactor",
            {
                pos = voxel,
                attenuate = true,
                is_relative = false
            }
        )
        reactor_ambience:set_component(RepeatableComponent.new(1, true))
        reactor_ambience:set_component(VoxelSoundComponent.of(voxel))
        reactor.sound = sound_entity_of(reactor_ambience, e)
    end
end

------------------

---@class SubterrinaReactorComponent : Component
---@field phase string
---@field sound SoundEntity?
SubterrinaReactorComponent = Component.of("subterrina/reactor")

---@param voxel_pos number[]
---@return SubterrinaReactorComponent
function SubterrinaReactorComponent.new()
    return SubterrinaReactorComponent:construct(
        { phase = "disabled" }
    )
end

------------------

---@param context IntentScriptContext
local function SetupSubterrinaScript(context)
    local world = context.world
    local type = context.inputs.type

    if type == "reactor" then
        local target = context.gen_target()
        local voxel_pos = target.voxel_pos
        local entity = world:set_dynamic_voxel(voxel_pos, true)
        entity:set_component(SubterrinaReactorComponent.new())
        context.feedback("subterrina reactor setup")
    end
end

local setup_subterrina = Script.new("setup_subterrina", SetupSubterrinaScript)

---@param context IntentScriptContext
local function SubterrinaReactorScript(context)
    local world = context.world
    local param = context.inputs.param
    local value = context.inputs.value
    local target = context.gen_target()
    local voxel_pos = target.voxel_pos
    local voxel = world:get_dynamic_voxel(voxel_pos)
    local reactor = nil
    local not_reactor = false
    if (voxel == nil) then
        not_reactor = true
    else
        reactor = voxel:get_component(SubterrinaReactorComponent)
        if (reactor == nil) then not_reactor = true end
    end
    if (not_reactor) then
        context.feedback("target is not a reactor")
        return
    end

    reactor[param] = value
    context.feedback("reactor value " .. param .. " = " .. value)
end

local subterrina_reactor = Script.new("reactor", SubterrinaReactorScript)

------------------

---@param result CompilationResult
function compile_subterrina(result)
    result:namespace({
        id = "subterrina",
        scripts = { setup_subterrina, subterrina_reactor },
        components = ComponentList { PersistentComponent("reactor") },
        intents = {
            Intent.of(
                    "setup_subterrina",
                    "subterrina/setup_subterrina",
                    true,
                    "Настроить субтеррину",
                    { IntentInput.of("type", "text") }
            ),
            Intent.of(
                    "subterrina_reactor",
                    "subterrina/reactor",
                    true,
                    "Настроить реактор",
                    { IntentInput.of("param", "text"), IntentInput.of("value", "text") }
            )
        }
    })
end

Callbacks.build()
        :system({ DynamicVoxelComponent, SubterrinaReactorComponent }, SubterrinaReactorSoundSystem, "client")
        :submit()
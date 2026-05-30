---@type World for EmmyLua
local World = World

---@class ReactorSoundLayer
---@field entity Entity|nil
---@field tween TweenEntity|nil
---@field enabled boolean|nil

---@class SubterrinaReactorSoundsComponent : Component
---@field layers table<string, ReactorSoundLayer>
SubterrinaReactorSoundsComponent = Component.of("subterrina/reactor_sounds")

---@return SubterrinaReactorSoundsComponent
function SubterrinaReactorSoundsComponent.new()
    return SubterrinaReactorSoundsComponent:construct({
        layers = {}
    })
end

---@class SubterrinaReactorComponent : Component
---@field phase string
---@field handled boolean
SubterrinaReactorComponent = Component.of("subterrina/reactor")

---@return SubterrinaReactorComponent
function SubterrinaReactorComponent.new()
    return SubterrinaReactorComponent:construct({
        phase = "disabled",
        handled = false
    })
end

------------------

local function sound_layer_of(sounds, name)
    local layer = sounds.layers[name]
    if layer == nil then
        layer = {
            entity = nil,
            tween = nil,
            enabled = nil
        }
        sounds.layers[name] = layer
    end
    return layer
end

local function create_reactor_ambience_entity(world, reactor_entity)
    local voxel = reactor_entity:get_component(DynamicVoxelComponent)
    if voxel == nil then
        return nil
    end

    local voxel_pos = voxel
    local sound_entity = world:add_sound_entity(
        "sounds/ambience_reactor",
        {
            pos = voxel_pos,
            spatial = true,
            radius = 10
        }
    )

    sound_entity:set_component(RepeatableComponent.new(1, true))
    sound_entity:set_component(VoxelSoundComponent.of(voxel_pos))
    return sound_entity
end

local function apply_layer_tween(world, entity, layer, enabled)
    local sound = entity:get_component(SoundComponent)
    if sound == nil then
        return
    end

    if layer.tween then
        layer.tween.entity:destroy()
        layer.tween = nil
    end

    local duration = 8 * 20
    local target_pitch = enabled and 1 or 0.95
    local target_volume = enabled and 1 or 0

    if enabled and sound.source.volume ~= 0 then
        sound.source.volume = 0
    end

    layer.tween = world:tween(entity)
       :with(Tween.pitch(sound.source.pitch, target_pitch, duration))
       :with(Tween.volume(sound.source.volume, target_volume, duration))
end

------------------

---@param world World
---@param entity Entity
---@param voxel DynamicVoxelComponent
---@param reactor SubterrinaReactorComponent
local function SubterrinaReactorEnsureSoundsSystem(world, entity, voxel, reactor)
    local sounds = entity:get_component(SubterrinaReactorSoundsComponent)
    if sounds == nil then
        sounds = SubterrinaReactorSoundsComponent.new()
        entity:set_component(sounds)
    end
end

---@param world World
---@param entity Entity
---@param reactor SubterrinaReactorComponent
---@param sounds SubterrinaReactorSoundsComponent
local function SubterrinaReactorSoundsSystem(world, entity, reactor, sounds)
    local enabled = reactor.phase ~= "disabled"
    local ambience = sound_layer_of(sounds, "ambience")

    if enabled and ambience.entity == nil then
        ambience.entity = create_reactor_ambience_entity(world, entity)
        if ambience.entity == nil then
            return
        end

        local sound = ambience.entity:get_component(SoundComponent)
        if sound then
            sound.source.volume = 0
        end
    end

    if ambience.entity == nil then
        return
    end

    if ambience.enabled ~= enabled then
        ambience.enabled = enabled
        apply_layer_tween(world, ambience.entity, ambience, enabled)
    end
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
        entity:set_component(SubterrinaReactorSoundsComponent.new())

        context.feedback("subterrina reactor setup")
    end
end

local setup_subterrina = Script.new("setup_subterrina", SetupSubterrinaScript)

---@param context IntentScriptContext
local function SubterrinaReactorScript(context)
    local world = context.world
    if world.is_client then return end

    local param = context.inputs.param
    local value = context.inputs.value
    local target = context.gen_target()
    local voxel_pos = target.voxel_pos
    local voxel = world:get_dynamic_voxel(voxel_pos)

    local reactor = nil
    local not_reactor = false

    if voxel == nil then
        not_reactor = true
    else
        reactor = voxel:get_component(SubterrinaReactorComponent)
        if reactor == nil then
            not_reactor = true
        end
    end

    if not_reactor then
        context.feedback("target is not a reactor")
        return
    end

    reactor[param] = value
    reactor.handled = false

    context.feedback("reactor value " .. param .. " = " .. value)
    voxel:mark_dirty(SubterrinaReactorComponent)
end

local subterrina_reactor = Script.new("reactor", SubterrinaReactorScript)

------------------

---@param result CompilationResult
function compile_subterrina(result)
    result:namespace({
        id = "subterrina",
        scripts = { setup_subterrina, subterrina_reactor },
        components = ComponentList {
            PersistentComponent("reactor"),
            "reactor_sounds"
        },
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
     :system({ DynamicVoxelComponent, SubterrinaReactorComponent }, SubterrinaReactorEnsureSoundsSystem, "client")
     :system({ SubterrinaReactorComponent, SubterrinaReactorSoundsComponent }, SubterrinaReactorSoundsSystem, "client")
     :submit()
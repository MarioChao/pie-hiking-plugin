--!strict

-- Lighting Zones Module


---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


---------- Imports ----------

local PieMapKit_SharedStorage = script.Parent.Parent.Parent

local _OtherModules = PieMapKit_SharedStorage:WaitForChild("OtherModules")
local ContainerMechanic = require(_OtherModules:WaitForChild("ContainerMechanic"))
local PriorityZoneGroup = require(_OtherModules:WaitForChild("PriorityZoneGroup"))

local _LightingModules = PieMapKit_SharedStorage:WaitForChild("LightingModules")
local UpdateLighting = require(_LightingModules:WaitForChild("UpdateLighting"))
local LightingTypes = require(_LightingModules:WaitForChild("Types"))


---------- Types ----------

type LightingConfig = LightingTypes.LightingConfigType

type LightingZoneConfig = {
	configInstance: Instance,
	getZonePriority: () -> number,
	priorityUpdated: RBXScriptSignal,
}


---------- Constants ----------

local Constants = {}

Constants.randomGenerator = Random.new()

Constants.localPlayer = nil :: Player?
if RunService:IsClient() then
	Constants.localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

Constants.configTagName = "LightingZoneConfig"

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.container_connections = {} :: {[Instance]: {RBXScriptConnection}?}
Globals.container_configInstance = {} :: {[Instance]: Instance?}

Globals.lightingZoneGroup = PriorityZoneGroup.new("LocalPlayer", workspace)


---------- Local functions ----------

local isSameLightingConfig

local getLightingConfig
local updateContainerLighting

local checkZonesLoopFrame

local getConfigFromInstance
local setUpContainer
local cleanUpContainer


----- Helper functions -----

isSameLightingConfig = function(config1: LightingConfig?, config2: LightingConfig?)
	if not config1 or not config2 then
		return false
	end

	for key, value in config1 do
		if config2[key] ~= value then
			return false
		end
	end
	for key, value in config2 do
		if config1[key] ~= value then
			return false
		end
	end

	return true
end


----- Lighting functions -----

getLightingConfig = function(parent: Instance): LightingConfig
	local result
	result = {}
	for _, child in parent:GetChildren() do
		if child.Name == "LightingConfig" and child:IsA("ModuleScript") then
			result = require(child) :: LightingConfig
			break
		end
	end
	return result
end

updateContainerLighting = function(container: Instance)
	-- Get lighting config
	local lightingConfig = getLightingConfig(container)

	-- Validate different lighting
	local lastAppliedLightingConfig = UpdateLighting.getLastAppliedLightingConfig()
	if isSameLightingConfig(lastAppliedLightingConfig, lightingConfig) then
		return
	end

	-- Set lighting
	UpdateLighting.applyLightingConfig(lightingConfig)
end


----- Zone functions -----

checkZonesLoopFrame = function()
	-- Validate local player
	if not Constants.localPlayer then
		return
	end

	-- Get player zones
	local filteredZoneFolders = Globals.lightingZoneGroup:getMaxPriorityZoneFolders_containPlayers({Constants.localPlayer})

	-- Check if player not in any zone
	if not next(filteredZoneFolders) then
		return
	end

	-- Select a container of highest priority
	local selectedContainer = filteredZoneFolders[Constants.randomGenerator:NextInteger(1, #filteredZoneFolders)]

	-- Update lighting
	local configInstance = Globals.container_configInstance[selectedContainer]
	if configInstance then
		updateContainerLighting(configInstance)
	end
end


----- Container mechanic -----

getConfigFromInstance = function(configInstance: Instance): LightingZoneConfig
    return {
		configInstance = configInstance,
		getZonePriority = function() return tonumber(configInstance:GetAttribute("ZonePriority")) or 0 end,
		priorityUpdated = configInstance:GetAttributeChangedSignal("ZonePriority"),
    }
end

setUpContainer = function(container: Instance, config: LightingZoneConfig)
	-- Clean up connections
	local existingConnections = Globals.container_connections[container]
	if existingConnections then
		for _, connection in existingConnections do
			connection:Disconnect()
		end
	end
	local newConnections = {}
	Globals.container_connections[container] = newConnections

	-- Store config instance
	Globals.container_configInstance[container] = config.configInstance

	-- Add to zone group
	Globals.lightingZoneGroup:addOrModifyZoneFolder(container, config.getZonePriority())

	-- Listen to priority update
	table.insert(newConnections, config.priorityUpdated:Connect(function()
		-- Update zone priority
		Globals.lightingZoneGroup:addOrModifyZoneFolder(container, config.getZonePriority())
	end))
end

cleanUpContainer = function(container: Instance)
	-- Remove from zone group
	Globals.lightingZoneGroup:removeZoneFolder(container)

	-- Clean up connections
	local existingConnections = Globals.container_connections[container]
	if existingConnections then
		for _, connection in existingConnections do
			connection:Disconnect()
		end
	end
	Globals.container_connections[container] = nil

	-- Clean up config instance
	Globals.container_configInstance[container] = nil
end


----- Main -----

local function main()
	if RunService:IsClient() then
		-- Set up container mechanic
		local mechanic = ContainerMechanic.new(Constants.configTagName)
		mechanic:setFunction_getConfigFromInstance(getConfigFromInstance)
		mechanic:setFunction_setUpContainer(setUpContainer)
		mechanic:setFunction_cleanUpContainer(cleanUpContainer)
		mechanic:setValidAncestors({workspace})
		mechanic:run()

		-- Heartbeat check on zones
		RunService.Heartbeat:Connect(checkZonesLoopFrame)
	elseif RunService:IsServer() then
		-- Do nothing
	end
end


---------- Calling function ----------

main()


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.addInstance(object: Instance)
	-- No need to do anything
end

function Module.removeInstance(object: Instance)
	-- No need to do anything
end


---------- Return module ----------

table.freeze(Module)
return Module

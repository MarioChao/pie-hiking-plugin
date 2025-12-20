--!strict

-- Lighting Zones Module


---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


---------- Imports ----------

local PieMapKit_SharedStorage = script.Parent.Parent.Parent

local _OtherModules = PieMapKit_SharedStorage:WaitForChild("OtherModules")
local SpatialQuery = require(_OtherModules:WaitForChild("SpatialQuery"))

local _LightingModules = PieMapKit_SharedStorage:WaitForChild("LightingModules")
local UpdateLighting = require(_LightingModules:WaitForChild("UpdateLighting"))
local LightingTypes = require(_LightingModules:WaitForChild("Types"))


---------- Types ----------

type ObjectConnections = {[Instance]: {RBXScriptConnection}}

type LightingConfig = LightingTypes.LightingConfigType


---------- Constants ----------

local Constants = {}

Constants.randomGenerator = Random.new()

Constants.localPlayer = nil :: Player?
if RunService:IsClient() then
	Constants.localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

-- Although no connections are made, this table is still used for accessing container instances
Globals.taggedContainerConnections = {} :: {[Instance]: ObjectConnections}

Globals.previousLightingConfig = nil :: LightingConfig?


---------- Local functions ----------

local createDefault
local getPlayerParts
local isSameLightingConfig

local getLightingConfig
local updateContainerLighting

local isPlayerInZone
local checkZonesLoopFrame


----- Helper functions -----

createDefault = function<K, V>(table: {[K]: V}, key: K, default: V)
	if not table[key] then
		table[key] = default
	end
end

getPlayerParts = function(player: Player)
	-- Get character
	local character = Constants.localPlayer and Constants.localPlayer.Character
	if not character then
		return {}
	end

	-- Add character parts to overlap param
	local result = {}
	for _, part in character:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end
		table.insert(result, part)
	end

	return result
end

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

getLightingConfig = function(container: Instance): LightingConfig
	local result
	result = {}
	for _, child in container:GetChildren() do
		if child.Name == "LightingConfig" and child:IsA("ModuleScript") then
			result = require(child) :: LightingConfig
			break
		end
	end
	return result
end


-- Update lighting

updateContainerLighting = function(container: Instance)
	-- Get lighting config
	local lightingConfig = getLightingConfig(container)

	-- Validate different lighting
	if isSameLightingConfig(Globals.previousLightingConfig, lightingConfig) then
		return
	end

	-- Set lighting
	Globals.previousLightingConfig = lightingConfig
	UpdateLighting.applyLightingConfig(lightingConfig)
end


----- Zone functions -----

-- Zone check

isPlayerInZone = function(playerParts: {BasePart}, container: Instance)
	-- Get zone parts
	local zoneParts = {}
	for _, part in container:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end
		table.insert(zoneParts, part)
	end

	-- Check zone contains player
	local containedParts = SpatialQuery.getWhitelistedInParts(playerParts, zoneParts, "LocalPlayer")

	-- Return result
	return #containedParts > 0
end

checkZonesLoopFrame = function()
	if not Constants.localPlayer then return end

	-- Get player parts
	local playerParts = getPlayerParts(Constants.localPlayer)

	-- Validate player alive
	if #playerParts == 0 then
		return
	end

	-- Get zones that contain the player
	local highestPriority = nil
	local priorityContainers: {[number]: {Instance}} = {}
	for zoneContainer, _ in Globals.taggedContainerConnections do
		-- Validate player in zone
		if not isPlayerInZone(playerParts, zoneContainer) then
			continue
		end

		-- Get container priority
		local zonePriority: number = zoneContainer:GetAttribute("Zone_Priority") :: number

		-- Update highest priority
		if (not highestPriority) or zonePriority > highestPriority then
			highestPriority = zonePriority
		end

		-- Store container at priority index
		createDefault(priorityContainers, zonePriority, {})
		table.insert(priorityContainers[zonePriority], zoneContainer)
	end

	-- Check if player not in any zone
	if not highestPriority then
		return
	end

	-- Select a container of highest priority
	local filteredContainers = priorityContainers[highestPriority]
	local selectedContainer = filteredContainers[Constants.randomGenerator:NextInteger(1, #filteredContainers)]

	-- Update lighting
	updateContainerLighting(selectedContainer)
end


----- Container set up -----

-- The container

local function setUpObjectContainer(container: Instance)
	-- Validate client
	if not RunService:IsClient() then
		return
	end

	-- Set up connections
	local objectConnections: ObjectConnections = {}
	Globals.taggedContainerConnections[container] = objectConnections
end

local function cleanUpObjectContainer(container: Instance)
	-- Disconnect and remove stored connections
	if Globals.taggedContainerConnections[container] then
		for object, connections in Globals.taggedContainerConnections[container] do
			for _, connection in connections do
				connection:Disconnect()
			end
			Globals.taggedContainerConnections[container][object] = nil
		end
		Globals.taggedContainerConnections[container] = nil
	end
end

local function validateObject(object: Instance)
	return object:IsA("Instance")
end


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.addInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Validate unique
	if Globals.taggedContainerConnections[object] then
		return
	end

	-- Set up object
	setUpObjectContainer(object)
end

function Module.removeInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Clean up object
	cleanUpObjectContainer(object)
end


---------- Set up function ----------

local function initSetUp()
	if RunService:IsClient() then
		-- Heartbeat check on zones
		RunService.Heartbeat:Connect(checkZonesLoopFrame)
	elseif RunService:IsServer() then
		-- Do nothing
	end
end


---------- Calling / connecting functions ----------

initSetUp()


---------- Return module ----------

table.freeze(Module)
return Module

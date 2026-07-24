--!strict

-- Lighting Zones Module

-- Converts legacy lighting zones to the newer version


---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


---------- Constants ----------

local Constants = {}

Constants.randomGenerator = Random.new()

Constants.localPlayer = nil :: Player?
if RunService:IsClient() then
	Constants.localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

Constants.newConfigTagName = "LightingZoneConfig"

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.tagged_tempInstances = {} :: {[Instance]: {Instance}?}


---------- Local functions ----------

local getLightingConfigModuleScript

local setUpObjectContainer
local cleanUpObjectContainer
local validateObject


----- Lighting functions -----

getLightingConfigModuleScript = function(container: Instance): ModuleScript?
	local result
	for _, child in container:GetChildren() do
		if child.Name == "LightingConfig" and child:IsA("ModuleScript") then
			result = child
			break
		end
	end
	return result
end


----- Container set up -----

-- The container

setUpObjectContainer = function(container: Instance)
	-- Validate client
	if not RunService:IsClient() then
		return
	end

	-- Initialize temporary instances
	local tempInstances: {Instance} = {}
	Globals.tagged_tempInstances[container] = tempInstances

	-- Create lighting zone config
	local lightingZoneConfig = Instance.new("Configuration")
	lightingZoneConfig.Name = Constants.newConfigTagName
	lightingZoneConfig:AddTag(Constants.newConfigTagName)

	-- Set config attributes
	lightingZoneConfig:SetAttribute("ZonePriority", container:GetAttribute("Zone_Priority"))

	-- Clone lighting config module script
	local lightingConfigModuleScript = getLightingConfigModuleScript(container)
	if lightingConfigModuleScript then
		local newConfigModuleScript = lightingConfigModuleScript:Clone()
		newConfigModuleScript.Parent = lightingZoneConfig
	else
		warn(`[Legacy Lighting Zones]: No 'LightingConfig' module script found for container '{container}'.`)
	end

	-- Parent & store config
	lightingZoneConfig.Parent = container
	table.insert(tempInstances, lightingZoneConfig)
end

cleanUpObjectContainer = function(container: Instance)
	-- Remove temporary instances
	local tempInstances = Globals.tagged_tempInstances[container]
	if tempInstances then
		for _, tempInstance in tempInstances do
			tempInstance:Destroy()
		end
		Globals.tagged_tempInstances[container] = nil
	end
end

validateObject = function(object: Instance)
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
	if Globals.tagged_tempInstances[object] then
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


---------- Return module ----------

table.freeze(Module)
return Module

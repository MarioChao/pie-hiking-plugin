--!strict
-- Load Lighting Script


---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end


---------- Services----------

local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")

local PieMapKit_SharedStorage = ReplicatedStorage:FindFirstChild("PieMapKit_SharedStorage")


---------- Imports ----------

local LightingModules = PieMapKit_SharedStorage:FindFirstChild("LightingModules")
local LightingTypes = require(LightingModules.Types)
local UpdateLighting = require(LightingModules.UpdateLighting)


---------- Instances ----------

local PieMapKitEvents = PieMapKit_SharedStorage:FindFirstChild("PieMapKitEvents")
local LightingBindable = PieMapKitEvents.LightingBindable


---------- Local functions ----------

local function loadLighting(lightingConfig: LightingTypes.LightingConfigType, name: string)
	print(`Loading {name}'s lighting configurations`)
	UpdateLighting.applyLightingConfig(lightingConfig)
end

local function loadDreamLighting(dreamFolder: Instance)
	-- Validate config
	local configModule = dreamFolder:FindFirstChild("LightingConfig")
	if not configModule then
		return
	end

	-- Load lighting
	local lightingConfig: LightingTypes.LightingConfigType = require(configModule)
	loadLighting(lightingConfig, dreamFolder.Name)
end


---------- Event functions ----------

local function onLightingBindableEvent(action: string, ...)
	if action == "LoadDreamLighting" then
		loadDreamLighting(...)
	end
end


---------- Calling / connecting functions ----------

LightingBindable.Event:Connect(onLightingBindableEvent)

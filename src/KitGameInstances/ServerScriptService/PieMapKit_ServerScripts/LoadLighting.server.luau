--!strict

-- Load Lighting


---------- Validate container ----------

-- Server script service
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end


---------- Services----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local PieMapKit_SharedStorage = ReplicatedStorage:FindFirstChild("PieMapKit_SharedStorage")

local LightingModules = PieMapKit_SharedStorage:FindFirstChild("LightingModules")
local LightingTypes = require(LightingModules.Types)
local UpdateLighting = require(LightingModules.UpdateLighting)


---------- Constants ----------

local Constants = {}

do
	local MapKit_Events = PieMapKit_SharedStorage:FindFirstChild("MapKit_Events")
	Constants.lightingBindable = MapKit_Events.LightingBindable
end

table.freeze(Constants)


---------- Local functions ----------

local loadLighting
local loadDreamLighting

local onLightingBindableEvent


----- Load lighting -----

loadLighting = function(lightingConfig: LightingTypes.LightingConfigType, name: string)
	print(`[Load Lighting]: Loading {name}'s lighting configurations`)
	UpdateLighting.applyLightingConfig(lightingConfig)
end

loadDreamLighting = function(dreamFolder: Instance)
	-- Validate config
	local configModule = dreamFolder:FindFirstChild("LightingConfig")
	if not (configModule and configModule:IsA("ModuleScript")) then
		return
	end

	-- Load lighting
	local success, _ = pcall(function()
		local lightingConfig = require(configModule) :: LightingTypes.LightingConfigType
		loadLighting(lightingConfig, dreamFolder.Name)
	end)
	if not success then
		warn(`[Load Lighting]: Load dream lighting unsuccessful.`)
	end
end


----- Lighting event -----

onLightingBindableEvent = function(action: string, ...)
	if action == "LoadDreamLighting" then
		loadDreamLighting(...)
	end
end


----- Main -----

local function main()
	Constants.lightingBindable.Event:Connect(onLightingBindableEvent)
end


---------- Calling function ----------

main()

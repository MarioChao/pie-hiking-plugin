--!strict

-- Update Lighting Module


---------- Services ----------

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


---------- Imports ----------

local LightingModules = script.Parent
local LightingTypes = require(LightingModules:WaitForChild("Types"))

local _OtherModules = LightingModules.Parent:WaitForChild("OtherModules")
local InstanceTween = require(_OtherModules:WaitForChild("InstanceTween"))


---------- Types ----------

type LightingConfigType = LightingTypes.LightingConfigType
type LightingProperties = LightingTypes.LightingProperties


---------- Constants ----------

local Constants = {}
Constants.lightingRemoteEvent = script.Parent:WaitForChild("LightingRemoteEvent")
Constants.remoteEventStrings = {
    server = {
        playerConnected = "Player Connected",
    },
    client = {
        updateLighting = "Update Lighting",
    },
}
table.freeze(Constants.remoteEventStrings)

Constants.defaultLightingProperties = {
	Ambient = Color3.fromRGB(70, 70, 70),
	Brightness = 3,
	ClockTime = 14.5,
	ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
	ColorShift_Top = Color3.fromRGB(0, 0, 0),
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 1,
	ExposureCompensation = 0,
	GlobalShadows = true,
	OutdoorAmbient = Color3.fromRGB(70, 70, 70),
	ShadowSoftness = 0.2,
	TimeOfDay = "14:30:00",
} :: LightingProperties
table.freeze(Constants.defaultLightingProperties)

Constants.postEffectClassNames = {
	"BloomEffect",
	"BlurEffect",
	"ColorCorrectionEffect",
	"ColorGradingEffect",
	"DepthOfFieldEffect",
	"SunRaysEffect",
}
table.freeze(Constants.postEffectClassNames)

Constants.default_postEffectClassName_instance = {
	BloomEffect = Instance.new("BloomEffect"),
	BlurEffect = Instance.new("BlurEffect"),
}
Constants.default_postEffectClassName_instance.BloomEffect.Intensity = 0
Constants.default_postEffectClassName_instance.BlurEffect.Size = 0
table.freeze(Constants.default_postEffectClassName_instance)

Constants.prefix = "UpdateLighting_"

Constants.defaultTweenInfo = TweenInfo.new(1)

table.freeze(Constants)


---------- Globals ----------

local Globals = {}
Globals.playerConnected = {} :: {[Player]: boolean}

Globals.lastAppliedLightingConfig = {} :: LightingConfigType


---------- Local functions ----------

local getOrRenameOrCreateChildInstance
local getClockTimeFromTimeOfDay
local updateAtmosphere
local updateLightingProperties
local updatePostEffects
local updateSky


----- Get or create -----

getOrRenameOrCreateChildInstance = function(parent: Instance, name: string, className: string)
	local foundChild
	local result
	foundChild = parent:FindFirstChild(name)
	if foundChild and foundChild:IsA(className) then
		result = foundChild
	else
		foundChild = parent:FindFirstChildWhichIsA(className)
		if foundChild then
			result = foundChild
			result.Name = name
		else
			if Constants.default_postEffectClassName_instance[className] then
				result = Constants.default_postEffectClassName_instance[className]:Clone()
			else
				result = Instance.new(className)
			end
			result.Parent = parent
			task.delay(1, function()
				result.Name = name
			end)
		end
	end
	return result
end


----- Get clock time -----

getClockTimeFromTimeOfDay = function(timeOfDay: string)
	local hours_str, minutes_str, seconds_str = string.match(timeOfDay, "(%d+):(%d+):(%d+)")
	local hours = tonumber(hours_str) or 0
	local minutes = tonumber(minutes_str) or 0
	local seconds = tonumber(seconds_str) or 0
	return hours + (minutes + seconds / 60) / 60
end


----- Update lighting -----

updateAtmosphere = function(atmosphere: Atmosphere?, tweenInfo: TweenInfo)
	local rootAtmosphere
	local propertyTable
	rootAtmosphere = getOrRenameOrCreateChildInstance(Lighting, Constants.prefix .. "Atmosphere", "Atmosphere") :: Atmosphere
	if atmosphere then
		propertyTable = InstanceTween.getWritablePropertyTableFromInstance(atmosphere)
	else
		propertyTable = {}
	end
	InstanceTween.tweenOrSetProperties(rootAtmosphere, propertyTable, {}, {}, tweenInfo, false)
end

updateLightingProperties = function(lightingProperties: LightingProperties?, tweenInfo: TweenInfo)
	local propertyTable = lightingProperties or table.clone(Constants.defaultLightingProperties)
	if propertyTable.TimeOfDay then
		propertyTable["ClockTime"] = getClockTimeFromTimeOfDay(propertyTable.TimeOfDay)
		propertyTable["TimeOfDay"] = nil
	end
	InstanceTween.tweenOrSetProperties(Lighting, propertyTable, Constants.defaultLightingProperties, {"TimeOfDay"}, tweenInfo, false)
end

updatePostEffects = function(postProcessing: {PostEffect}?, tweenInfo: TweenInfo)
	local className_postEffect = {} :: {[string]: PostEffect}
	local effectInstance
	local propertyTable

	-- Get post effects dictionary
	if postProcessing then
		for _, postEffect in postProcessing do
			if className_postEffect[postEffect.ClassName] then
				warn(`[Update Lighting]: Duplicate {postEffect.ClassName} found!`)
			else
				className_postEffect[postEffect.ClassName] = postEffect
			end
		end
	end

	-- Go through post effect classes
	for _, className in Constants.postEffectClassNames do
		effectInstance = getOrRenameOrCreateChildInstance(Lighting, Constants.prefix .. className, className) :: PostEffect
		if className_postEffect[className] then
			propertyTable = InstanceTween.getWritablePropertyTableFromInstance(className_postEffect[className])
		elseif Constants.default_postEffectClassName_instance[className] then
			propertyTable = Constants.default_postEffectClassName_instance[className]
		else
			propertyTable = {}
		end
		InstanceTween.tweenOrSetProperties(effectInstance, propertyTable, {}, {}, tweenInfo, false)
	end
end

updateSky = function(sky: Sky?, tweenInfo: TweenInfo)
	local rootSky
	local propertyTable
	rootSky = getOrRenameOrCreateChildInstance(Lighting, Constants.prefix .. "Sky", "Sky") :: Sky
	if sky then
		propertyTable = InstanceTween.getWritablePropertyTableFromInstance(sky)
	else
		propertyTable = {}
	end
	InstanceTween.tweenOrSetProperties(rootSky, propertyTable, {}, {}, tweenInfo, false)
end


----- Main -----

local function main()
	if RunService:IsServer() then
		Constants.lightingRemoteEvent.OnServerEvent:Connect(function(player: Player, mode: string)
			if mode == Constants.remoteEventStrings.server.playerConnected then
				Globals.playerConnected[player] = true
			end
		end)
		Players.PlayerRemoving:Connect(function(player: Player)
			Globals.playerConnected[player] = nil
		end)
	end
end


---------- Calling function ----------

task.defer(main)


---------- Module ----------

local UpdateLightingModule = {}


----- Module fields -----

function UpdateLightingModule.applyLightingConfig(lightingConfig: LightingConfigType?, specificPlayer: Player?)
	if not lightingConfig then
		return
	end
	if RunService:IsServer() then
		if specificPlayer then
			task.defer(function()
				local startTime = time()
				while not Globals.playerConnected[specificPlayer] and time() - startTime < 5 do
					task.wait()
				end
				if Globals.playerConnected[specificPlayer] then
					Constants.lightingRemoteEvent:FireClient(specificPlayer, Constants.remoteEventStrings.client.updateLighting, lightingConfig)
				end
			end)
		else
			for _, player in Players:GetPlayers() do
				UpdateLightingModule.applyLightingConfig(lightingConfig, player)
			end
			task.defer(function()
				local instantTween = TweenInfo.new(0)
				updateAtmosphere(lightingConfig.Atmosphere, instantTween)
				updateLightingProperties(lightingConfig.Lighting, instantTween)
				updatePostEffects(lightingConfig.PostProcessing, instantTween)
				updateSky(lightingConfig.Sky, instantTween)
			end)
		end
	else
		local tweenInfo
		if lightingConfig.tweenDuration then
			tweenInfo = TweenInfo.new(lightingConfig.tweenDuration)
		else
			tweenInfo = Constants.defaultTweenInfo
		end
		Globals.lastAppliedLightingConfig = lightingConfig
		updateAtmosphere(lightingConfig.Atmosphere, tweenInfo)
		updateLightingProperties(lightingConfig.Lighting, tweenInfo)
		updatePostEffects(lightingConfig.PostProcessing, tweenInfo)
		updateSky(lightingConfig.Sky, tweenInfo)
	end
end

function UpdateLightingModule.getLastAppliedLightingConfig()
	return Globals.lastAppliedLightingConfig
end


---------- Return module ----------

table.freeze(UpdateLightingModule)
return UpdateLightingModule

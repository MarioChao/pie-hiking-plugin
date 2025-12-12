--!strict

-- Update Lighting Module


---------- Services ----------

local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


---------- Imports ----------

local LightingModules = script.Parent
local LightingTypes = require(LightingModules.Types)


---------- Types ----------

type LightingConfigType = LightingTypes.LightingConfigType
type LightingProperties = LightingTypes.LightingProperties
type PostEffectTypes = LightingTypes.PostEffectTypes


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

table.freeze(Constants)


---------- Globals ----------

local Globals = {}
Globals.playerConnected = {} :: {[Player]: boolean}


---------- Local functions ----------

local updateAtmosphere
local updateLightingProperties
local updatePostEffects
local updateSky


----- Update lighting -----

updateAtmosphere = function(atmosphere: Atmosphere?)
	-- Validate atmosphere
	if not atmosphere then
		return
	end

	-- Remove old atmosphere
	for _, object in Lighting:GetChildren() do
		if object:IsA("Atmosphere") then
			Debris:AddItem(object, 0)
		end
	end

	-- Clone new atmosphere
	local newAtmosphere = atmosphere:Clone()
	newAtmosphere.Parent = Lighting
end

updateLightingProperties = function(lightingProperties: LightingProperties?)
	-- Validate lighting properties
	if not lightingProperties then
		return
	end

	-- Update lighting properties
	local success, result = pcall(function()
		for property, value in lightingProperties do
			Lighting[property] = value
		end
	end)
	if not success then
		warn("[Update Lighting]: Update lighting error:", result)
	end
end

updatePostEffects = function(postProcessing: PostEffectTypes?)
	-- Validate post effects
	if not postProcessing then
		return
	end

	-- Go through post effects
	for _, effect in postProcessing do
		-- Validate effect
		if not effect then
			continue
		end

		-- Clone new effect
		local newEffect = (effect :: PostEffect):Clone()

		-- Remove old effects
		for _, object in Lighting:GetChildren() do
			if object:IsA(newEffect.Name) then
				Debris:AddItem(object, 0)
			end
		end

		-- Parent new effect
		newEffect.Parent = Lighting
	end
end

updateSky = function(sky: Sky?)
	-- Validate sky
	if not sky then
		return
	end

	-- Remove old sky
	for _, object in Lighting:GetChildren() do
		if object:IsA("Sky") then
			Debris:AddItem(object, 0)
		end
	end

	-- Clone new sky
	local newSky = sky:Clone()
	newSky.Parent = Lighting
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
	if specificPlayer and RunService:IsServer() then
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
		updateAtmosphere(lightingConfig.Atmosphere)
		updateLightingProperties(lightingConfig.Lighting)
		updatePostEffects(lightingConfig.PostProcessing)
		updateSky(lightingConfig.Sky)
	end
end


---------- Return module ----------

table.freeze(UpdateLightingModule)
return UpdateLightingModule

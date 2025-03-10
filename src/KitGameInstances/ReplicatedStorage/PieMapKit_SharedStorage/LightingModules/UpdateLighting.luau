--!strict
-- Update Lighting Module

---------- Module ----------
local UpdateLightingModule = {}

---------- Services ----------

local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

---------- Imports ----------

local LightingModules = script.Parent
local LightingTypes = require(LightingModules.Types)

---------- Types ----------

type LightingConfigType = LightingTypes.LightingConfigType
type LightingProperties = LightingTypes.LightingProperties
type PostEffectTypes = LightingTypes.PostEffectTypes

---------- Local functions ----------

local function updateAtmosphere(atmosphere: Atmosphere?)
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

local function updateLightingProperties(lightingProperties: LightingProperties?)
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
		warn("Update lighting error:", result)
	end
end

local function updatePostEffects(postProcessing: PostEffectTypes?)
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

local function updateSky(sky: Sky?)
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

---------- Module functions ----------
function UpdateLightingModule.applyLightingConfig(lightingConfig: LightingConfigType?)
	if not lightingConfig then
		return
	end

	updateAtmosphere(lightingConfig.Atmosphere)
	updateLightingProperties(lightingConfig.Lighting)
	updatePostEffects(lightingConfig.PostProcessing)
	updateSky(lightingConfig.Sky)

end

---------- Return module ----------
return UpdateLightingModule

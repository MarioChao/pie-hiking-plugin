--!strict

-- Legacy Music Zones

-- Converts legacy music zones to the newer version


---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


---------- Types ----------

type AudioInfo = {
	AssetId: number | string,
	LoopRegion: NumberRange,
	PlaybackRegion: NumberRange,
	PlaybackSpeed: number,
	Volume: number,
}


---------- Constants ----------

local Constants = {}

Constants.localPlayer = nil :: Player?
if RunService:IsClient() then
	Constants.localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

Constants.newConfigTagName = "MusicZoneConfig"

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.tagged_tempInstances = {} :: {[Instance]: {Instance}?}


---------- Local functions ----------

local getAudioInfo
local createSoundFromAudioInfo

local setUpObjectContainer
local cleanUpObjectContainer
local validateObject


----- Music functions -----

getAudioInfo = function(container: Instance): AudioInfo?
	local result
	if container:GetAttribute("FromSound") then
		local sound = container:FindFirstChildWhichIsA("Sound")
		if sound then
			result = {
				AssetId = sound.SoundId,
				LoopRegion = sound.PlaybackRegionsEnabled and sound.LoopRegion or NumberRange.new(0),
				PlaybackRegion = sound.PlaybackRegionsEnabled and sound.PlaybackRegion or NumberRange.new(0),
				PlaybackSpeed = sound.PlaybackSpeed,
				Volume = sound.Volume,
			}
		else
			warn(`[Legacy Music Zones]: No sound instance found for container '{container}'!`)
		end
	else
		result = {
			AssetId = tostring(container:GetAttribute("Audio_AssetId")) :: string,
			LoopRegion = container:GetAttribute("Audio_LoopRegion") :: NumberRange,
			PlaybackRegion = container:GetAttribute("Audio_PlaybackRegion") :: NumberRange,
			PlaybackSpeed = container:GetAttribute("Audio_PlaybackSpeed") :: number,
			Volume = container:GetAttribute("Audio_Volume") :: number,
		}
	end
	return result
end

createSoundFromAudioInfo = function(audioInfo: AudioInfo)
	local sound = Instance.new("Sound")
	if tonumber(audioInfo.AssetId) then
		sound.SoundId = `rbxassetid://{audioInfo.AssetId}`
	else
		sound.SoundId = tostring(audioInfo.AssetId)
	end
	sound.PlaybackRegionsEnabled = true
	sound.LoopRegion = audioInfo.LoopRegion
	sound.PlaybackRegion = audioInfo.PlaybackRegion
	sound.PlaybackSpeed = audioInfo.PlaybackSpeed
	sound.Volume = audioInfo.Volume
	return sound
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

	-- Create music zone config
	local musicZoneConfig = Instance.new("Configuration")
	musicZoneConfig.Name = Constants.newConfigTagName
	musicZoneConfig:AddTag(Constants.newConfigTagName)

	-- Set config attributes
	musicZoneConfig:SetAttribute("ZonePriority", container:GetAttribute("Zone_Priority"))

	-- Clone sound instance for audio info
	local audioInfo = getAudioInfo(container)
	if audioInfo then
		local sound = createSoundFromAudioInfo(audioInfo)
		sound.Name = "ZoneSound"
		sound.Parent = musicZoneConfig
	else
		warn(`[Legacy Music Zones]: Unable to retrieve audio info for container '{container}'.`)
	end

	-- Parent & store config
	musicZoneConfig.Parent = container
	table.insert(tempInstances, musicZoneConfig)
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

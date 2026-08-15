--!strict

-- Music Zones Module


---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


---------- Imports ----------

local PieMapKit_SharedStorage = script.Parent.Parent.Parent
local _OtherModules = PieMapKit_SharedStorage:WaitForChild("OtherModules")
local ContainerMechanic = require(_OtherModules:WaitForChild("ContainerMechanic"))
local PriorityZoneGroup = require(_OtherModules:WaitForChild("PriorityZoneGroup"))


---------- Types ----------

type AudioInfo = {
	AssetId: number | string,
	LoopRegion: NumberRange,
	PlaybackRegion: NumberRange,
	PlaybackSpeed: number,
	Volume: number,
}

type MusicZoneConfig = {
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

Constants.configTagName = "MusicZoneConfig"

Constants.mapKit_events = PieMapKit_SharedStorage:WaitForChild("MapKit_Events")
Constants.musicBindable = Constants.mapKit_events:WaitForChild("MusicBindable")

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.container_connections = {} :: {[Instance]: {RBXScriptConnection}?}
Globals.container_configInstance = {} :: {[Instance]: Instance?}

Globals.musicZoneGroup = PriorityZoneGroup.new("LocalPlayer", workspace)

Globals.previousAudio = nil :: AudioInfo?


---------- Local functions ----------

local isSameAudio

local getAudioInfo
local playContainerMusic

local checkZonesLoopFrame

local getConfigFromInstance
local setUpContainer
local cleanUpContainer


----- Helper functions -----

isSameAudio = function(audio1: AudioInfo?, audio2: AudioInfo?)
	if not audio1 or not audio2 then
		return false
	end

	for key, value in audio1 do
		if audio2[key] ~= value then
			return false
		end
	end
	for key, value in audio2 do
		if audio1[key] ~= value then
			return false
		end
	end

	return true
end


----- Music functions -----

getAudioInfo = function(parent: Instance): AudioInfo?
	local result
	local sound = parent:FindFirstChildWhichIsA("Sound")
	if sound then
		result = {
			AssetId = sound.SoundId,
			LoopRegion = sound.PlaybackRegionsEnabled and sound.LoopRegion or NumberRange.new(0),
			PlaybackRegion = sound.PlaybackRegionsEnabled and sound.PlaybackRegion or NumberRange.new(0),
			PlaybackSpeed = sound.PlaybackSpeed,
			Volume = sound.Volume,
		}
	else
		warn(`[Music Zones]: No sound instance found for "{parent}!"`)
	end
	return result
end

playContainerMusic = function(container: Instance)
	-- Get music info
	local audioInfo = getAudioInfo(container)

	-- Validate different music
	if isSameAudio(Globals.previousAudio, audioInfo) then
		return
	end

	-- Set music
	Globals.previousAudio = audioInfo
	Constants.musicBindable:Fire("SetAudio", audioInfo)
end


----- Zone functions -----

checkZonesLoopFrame = function()
	-- Validate local player
	if not Constants.localPlayer then
		return
	end

	-- Get player zones
	local filteredZoneFolders = Globals.musicZoneGroup:getMaxPriorityZoneFolders_containPlayers({Constants.localPlayer})

	-- Check if player not in any zone
	if not next(filteredZoneFolders) then
		-- Validate different music
		if not Globals.previousAudio then
			return
		end

		-- Play default audio
		Globals.previousAudio = nil
		Constants.musicBindable:Fire("PlayDefaultAudio")
		return
	end

	-- Select a container of highest priority
	local selectedContainer = filteredZoneFolders[Constants.randomGenerator:NextInteger(1, #filteredZoneFolders)]

	-- Play container music
	local configInstance = Globals.container_configInstance[selectedContainer]
	if configInstance then
		playContainerMusic(configInstance)
	end
end


----- Container mechanic -----

getConfigFromInstance = function(configInstance: Instance): MusicZoneConfig
    return {
		configInstance = configInstance,
		getZonePriority = function() return tonumber(configInstance:GetAttribute("ZonePriority")) or 0 end,
		priorityUpdated = configInstance:GetAttributeChangedSignal("ZonePriority"),
    }
end

setUpContainer = function(container: Instance, config: MusicZoneConfig)
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
	Globals.musicZoneGroup:addOrModifyZoneFolder(container, config.getZonePriority())

	-- Listen to priority update
	table.insert(newConnections, config.priorityUpdated:Connect(function()
		-- Update zone priority
		Globals.musicZoneGroup:addOrModifyZoneFolder(container, config.getZonePriority())
	end))
end

cleanUpContainer = function(container: Instance)
	-- Remove from zone group
	Globals.musicZoneGroup:removeZoneFolder(container)

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

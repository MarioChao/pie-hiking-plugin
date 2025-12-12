--!strict

-- Music Zones Module


---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PieMapKit_SharedStorage = script.Parent.Parent.Parent


---------- Imports ----------

local OtherModules = PieMapKit_SharedStorage.OtherModules
local SpatialQuery = require(OtherModules.SpatialQuery)


---------- Types ----------

type ObjectConnections = {[Instance]: {RBXScriptConnection}}

type AudioInfo = {
	AssetId: number | string,
	LoopRegion: NumberRange,
	PlaybackRegion: NumberRange,
	PlaybackSpeed: number,
	Volume: number,
}


---------- Constants ----------

local Constants = {}

Constants.randomGenerator = Random.new()

Constants.localPlayer = nil :: Player?
if RunService:IsClient() then
	Constants.localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

Constants.pieMapKitEvents = PieMapKit_SharedStorage:WaitForChild("PieMapKitEvents")
Constants.musicBindable = Constants.pieMapKitEvents:WaitForChild("MusicBindable")

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

-- Although no connections are made, this table is still used for accessing container instances
Globals.taggedContainerConnections = {} :: {[Instance]: ObjectConnections}

Globals.previousAudio = nil :: AudioInfo?


---------- Local functions ----------

local createDefault
local getPlayerParts
local isSameAudio

local getAudioInfo
local playContainerMusic
local isPlayerInMusicZone
local checkMusicZonesFrame


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

isSameAudio = function(audio1: AudioInfo?, audio2: AudioInfo?)
	if not audio1 or not audio2 then
		return false
	end

	for key, value in audio1 do
		if audio2[key] ~= value then
			return false
		end
	end
	return true
end


----- Music functions -----
-- Define general functions here


getAudioInfo = function(container: Instance): AudioInfo
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
			warn(`[Music Zones]: No sound instance found for "{container}!"`)
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


-- Play music

playContainerMusic = function(container: Instance)
	-- Get music info
	local audioInfo: AudioInfo = getAudioInfo(container)

	-- Validate different music
	if isSameAudio(Globals.previousAudio, audioInfo) then
		return
	end

	-- Set music
	Globals.previousAudio = audioInfo
	Constants.musicBindable:Fire("SetAudio", audioInfo)
end


-- Zone check

isPlayerInMusicZone = function(playerParts: {BasePart}, container: Instance)
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

checkMusicZonesFrame = function()
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
		if not isPlayerInMusicZone(playerParts, zoneContainer) then
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
	local filteredContainers = priorityContainers[highestPriority]
	local selectedContainer = filteredContainers[Constants.randomGenerator:NextInteger(1, #filteredContainers)]

	-- Play container music
	playContainerMusic(selectedContainer)
end


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
		RunService.Heartbeat:Connect(checkMusicZonesFrame)
	elseif RunService:IsServer() then
		-- Do nothing
	end
end


---------- Calling / connecting functions ----------

initSetUp()


---------- Return module ----------

table.freeze(Module)
return Module

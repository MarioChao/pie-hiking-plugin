--!strict
-- Music Zones Module


---------- Module ----------
local Module = {}


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
	AssetId: number,
	LoopRegion: NumberRange,
	PlaybackRegion: NumberRange,
	PlaybackSpeed: number,
	Volume: number,
}


---------- Instances ----------

local LocalPlayer: Player
if RunService:IsClient() then
	LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

local PieMapKitEvents = PieMapKit_SharedStorage.PieMapKitEvents
local MusicBindable = PieMapKitEvents.MusicBindable


---------- Variables ----------

-- Although no connections are made, this table is still used for accessing container instances
local taggedContainerConnections: {[Instance]: ObjectConnections} = {}

local previousAudio: AudioInfo? = nil

local randomGenerator = Random.new()


---------- Helper functions ----------

local function createDefault<K, V>(table: {[K]: V}, key: K, default: V)
	if not table[key] then
		table[key] = default
	end
end

local function getPlayerParts(player: Player)
	-- Get character
	local character = LocalPlayer.Character
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

local function isSameAudio(audio1: AudioInfo, audio2: AudioInfo)
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


---------- Local functions ----------
-- Define general functions here


-- Play music

local function playContainerMusic(container: Instance)
	-- Get music info
	local audioInfo: AudioInfo = {
		AssetId = container:GetAttribute("Audio_AssetId"),
		LoopRegion = container:GetAttribute("Audio_LoopRegion"),
		PlaybackRegion = container:GetAttribute("Audio_PlaybackRegion"),
		PlaybackSpeed = container:GetAttribute("Audio_PlaybackSpeed"),
		Volume = container:GetAttribute("Audio_Volume"),
	}

	-- Validate different music
	if isSameAudio(previousAudio, audioInfo) then
		return
	end

	-- Set music
	previousAudio = audioInfo
	MusicBindable:Fire("SetAudio", audioInfo)
end


-- Zone check

local function isPlayerInMusicZone(playerParts: {BasePart}, container: Instance)
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

local function checkMusicZonesFrame()
	-- Get player parts
	local playerParts = getPlayerParts(LocalPlayer)

	-- Validate player alive
	if #playerParts == 0 then
		return
	end

	-- Get zones that contain the player
	local highestPriority = nil
	local priorityContainers: {[number]: {Instance}} = {}
	for zoneContainer, _ in taggedContainerConnections do
		-- Validate player in zone
		if not isPlayerInMusicZone(playerParts, zoneContainer) then
			continue
		end

		-- Get container priority
		local zonePriority: number = zoneContainer:GetAttribute("Zone_Priority")

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
		if not previousAudio then
			return
		end

		-- Play default audio
		previousAudio = nil
		MusicBindable:Fire("PlayDefaultAudio")
		return
	end

	-- Select a container of highest priority
	local filteredContainers = priorityContainers[highestPriority]
	local selectedContainer = filteredContainers[randomGenerator:NextInteger(1, #filteredContainers)]

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
	taggedContainerConnections[container] = objectConnections
end

local function cleanUpObjectContainer(container: Instance)
	-- Disconnect and remove stored connections
	if taggedContainerConnections[container] then
		for object, connections in taggedContainerConnections[container] do
			for _, connection in connections do
				connection:Disconnect()
			end
			taggedContainerConnections[container][object] = nil
		end
		taggedContainerConnections[container] = nil
	end
end

local function validateObject(object: Instance)
	return object:IsA("Instance")
end


---------- Module functions ----------

function Module.addInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Validate unique
	if taggedContainerConnections[object] then
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
return Module

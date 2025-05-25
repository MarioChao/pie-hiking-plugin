--!strict
-- Server Map Controller Script


---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PieMapKit_SharedStorage = ReplicatedStorage:FindFirstChild("PieMapKit_SharedStorage")


---------- Imports ----------

local PieMapKitModules = PieMapKit_SharedStorage:WaitForChild("PieMapKitModules")
local DreamMaps = require(PieMapKitModules.DreamMaps)
require(PieMapKitModules.MapObjects)


---------- Types ----------


---------- Instances ----------

local PieMapKitEvents = PieMapKit_SharedStorage:WaitForChild("PieMapKitEvents")
local LoadDreamBindable = PieMapKitEvents.LoadDreamBindable
local LoadDreamRemote = PieMapKitEvents.LoadDreamRemote
local LightingBindable = PieMapKitEvents.LightingBindable

local DefaultDreamValue: ObjectValue = workspace:FindFirstChild("_DefaultDreamValue", true)
local DefaultDream = DefaultDreamValue.Value

local DreamStorage = ServerStorage:FindFirstChild("DreamStorage") or Instance.new("Folder")
DreamStorage.Name = "DreamStorage"
DreamStorage.Parent = ServerStorage


---------- Variables ----------

local mapTagName = "HikeMap"

local savedMapFolder: {[Instance]: Folder} = {}

local activeClientDreamMapFolder: {[Instance]: Instance} = {}


---------- Local functions ----------
-- Define general functions here

local function getMapFolder(dreamFolder: Instance)
	for _, object in dreamFolder:GetChildren() do
		if object:HasTag(mapTagName) then
			return object
		end
	end
	return nil
end

local function loadDream(dreamFolder: Instance)
	-- Validate map
	local mapFolder = getMapFolder(dreamFolder)
	if not mapFolder then
		return
	end

	-- Load dream
	dreamFolder.Parent = workspace

	if dreamFolder:GetAttribute("IsClientMap") then
		-- Move map to replicated storage
		savedMapFolder[dreamFolder] = mapFolder
		mapFolder.Parent = ReplicatedStorage

		-- Load dream on client
		LoadDreamRemote:FireAllClients("LoadClientDream", dreamFolder, mapFolder)
		activeClientDreamMapFolder[dreamFolder] = mapFolder
	end

	-- Load lighting
	LightingBindable:Fire("LoadDreamLighting", dreamFolder)
end

local function unloadDream(dreamFolder: Instance)
	-- Unload dream on client
	LoadDreamRemote:FireAllClients("UnloadDream", dreamFolder)
	activeClientDreamMapFolder[dreamFolder] = nil

	-- Move the dream to storage
	dreamFolder.Parent = DreamStorage

	-- Move map if saved
	if savedMapFolder[dreamFolder] then
		savedMapFolder[dreamFolder].Parent = dreamFolder
		savedMapFolder[dreamFolder] = nil
	end
end


---------- Event functions ----------
-- Functions that are directly connected by events or signals

local function onPlayerAdded(player: Player)
	for dreamFolder, mapFolder in activeClientDreamMapFolder do
		-- Validate map folder
		if not mapFolder then
			return
		end

		-- Load dream on client
		LoadDreamRemote:FireClient(player, "LoadClientDream", dreamFolder, mapFolder)
	end
end

local function allPlayerEvents()
	local players = Players:GetPlayers()
	task.defer(function()
		for _, player in players do
			onPlayerAdded(player)
		end
	end)
	Players.PlayerAdded:Connect(onPlayerAdded)
end

local function onDreamAddedEvent(dreamFolder: Folder)
	-- Validate dream
	if not (dreamFolder and dreamFolder:GetAttribute("DreamDifficulty")) then
		return
	end

	-- Load or unload dream
	if dreamFolder == DefaultDream then
		loadDream(dreamFolder)
	else
		unloadDream(dreamFolder)
	end
end

local function onLoadDreamBindableEvent(action: string, ...)
	if action == "LoadDream" then
		loadDream(...)
	elseif action == "UnloadDream" then
		unloadDream(...)
	end
end


---------- Set up function ----------
local function initSetUp()
	-- Dream maps
	local dreams = DreamMaps.getAllDreams()
	task.defer(function()
		for _, dreamFolder in dreams do
			onDreamAddedEvent(dreamFolder)
		end
	end)
	DreamMaps.dreamAdded.Event:Connect(onDreamAddedEvent)

	-- Players
	allPlayerEvents()
end


---------- Calling / connecting functions ----------
-- Connect functions to events and signals, then call set up functions

LoadDreamBindable.Event:Connect(onLoadDreamBindableEvent)
initSetUp()

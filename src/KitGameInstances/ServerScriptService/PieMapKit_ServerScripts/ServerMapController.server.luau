--!strict

-- Server Map Controller


---------- Validate container ----------

-- Server script service
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")


---------- Imports ----------

local PieMapKit_SharedStorage = ReplicatedStorage:FindFirstChild("PieMapKit_SharedStorage")

local MapKit_Modules = PieMapKit_SharedStorage:WaitForChild("MapKit_Modules")
local DreamMaps = require(MapKit_Modules.DreamMaps)
require(MapKit_Modules.MapObjects)


---------- Constants ----------

local Constants = {}

Constants.dreamFolderTagName = "DreamFolder"
Constants.mapTagName = "HikeMap"
Constants.autoUnloadAttributeName = "AutoUnload"

do
	local MapKit_Events = PieMapKit_SharedStorage:WaitForChild("MapKit_Events")
	Constants.loadDreamBindable = MapKit_Events.LoadDreamBindable
	Constants.loadDreamRemote = MapKit_Events.LoadDreamRemote
	Constants.lightingBindable = MapKit_Events.LightingBindable
end

do
	local DefaultDreamValue: ObjectValue? = workspace:FindFirstChild("_DefaultDreamValue", true)
	Constants.defaultDream = DefaultDreamValue and DefaultDreamValue.Value
end

Constants.dreamStorage = ServerStorage:FindFirstChild("DreamStorage") or Instance.new("Folder")
Constants.dreamStorage.Name = "DreamStorage"
Constants.dreamStorage.Parent = ServerStorage

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.dream_savedMapFolder = {} :: {[Instance]: Instance}

Globals.activeClientDream_mapFolder = {} :: {[Instance]: Instance}


---------- Local functions ----------

local getIsDreamFolder
local getMapFolder
local loadDream
local unloadDream

local onPlayerAdded
local allPlayerEvents
local onDreamAddedEvent
local onLoadDreamBindableEvent


----- Dreams -----

getIsDreamFolder = function(object: Instance): boolean
	return object and (object:HasTag(Constants.dreamFolderTagName) or object:GetAttribute("DreamDifficulty") ~= nil)
end

getMapFolder = function(dreamFolder: Instance): Instance?
	for _, object in dreamFolder:GetChildren() do
		if object:HasTag(Constants.mapTagName) then
			return object
		end
	end
	return nil
end

loadDream = function(dreamFolder: Instance)
	-- Validate map
	local mapFolder = getMapFolder(dreamFolder)
	if not mapFolder then
		return
	end

	-- Load dream
	dreamFolder.Parent = workspace

	if dreamFolder:GetAttribute("IsClientMap") then
		-- Move map to replicated storage
		Globals.dream_savedMapFolder[dreamFolder] = mapFolder
		mapFolder.Parent = ReplicatedStorage

		-- Load dream on client
		Constants.loadDreamRemote:FireAllClients("LoadClientDream", dreamFolder, mapFolder)
		Globals.activeClientDream_mapFolder[dreamFolder] = mapFolder
	end

	-- Load lighting
	Constants.lightingBindable:Fire("LoadDreamLighting", dreamFolder)
end

unloadDream = function(dreamFolder: Instance)
	-- Unload dream on client
	Constants.loadDreamRemote:FireAllClients("UnloadDream", dreamFolder)
	Globals.activeClientDream_mapFolder[dreamFolder] = nil

	-- Move the dream to storage
	dreamFolder.Parent = Constants.dreamStorage

	-- Move map back if saved
	if Globals.dream_savedMapFolder[dreamFolder] then
		Globals.dream_savedMapFolder[dreamFolder].Parent = dreamFolder
		Globals.dream_savedMapFolder[dreamFolder] = nil
	end
end


----- Event functions -----

onPlayerAdded = function(player: Player)
	for dreamFolder, mapFolder in Globals.activeClientDream_mapFolder do
		-- Validate map folder
		if not mapFolder then
			return
		end

		-- Load dream on client
		Constants.loadDreamRemote:FireClient(player, "LoadClientDream", dreamFolder, mapFolder)
	end
end

allPlayerEvents = function()
	local players = Players:GetPlayers()
	task.defer(function()
		for _, player in players do
			onPlayerAdded(player)
		end
	end)
	Players.PlayerAdded:Connect(onPlayerAdded)
end

onDreamAddedEvent = function(dreamFolder: Instance)
	-- Validate dream
	if not getIsDreamFolder(dreamFolder) then
		return
	end

	-- Load or unload dream
	if dreamFolder == Constants.defaultDream then
		loadDream(dreamFolder)
	else
		if dreamFolder:GetAttribute(Constants.autoUnloadAttributeName) then
			unloadDream(dreamFolder)
		else
			loadDream(dreamFolder)
		end
	end
end

onLoadDreamBindableEvent = function(action: string, ...)
	if action == "LoadDream" then
		loadDream(...)
	elseif action == "UnloadDream" then
		unloadDream(...)
	end
end


----- Main -----

local function main()
	-- Load dream event
	Constants.loadDreamBindable.Event:Connect(onLoadDreamBindableEvent)

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


---------- Calling function ----------

main()

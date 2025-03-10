--!strict
-- Dream Maps Module

---------- Module ----------
local DreamMaps = {}

---------- Services ----------

local CollectionService = game:GetService("CollectionService")

---------- Types ----------

---------- Instances ----------

---------- Variables ----------

local mapTagName = "HikeMap"

local storedDreamFolders: {Instance} = {}

---------- Module variables ----------

-- Fires when a new dream folder is stored (tagged)
DreamMaps.dreamAdded = Instance.new("BindableEvent")

-- Fires when a dream folder is removed (untagged)
DreamMaps.dreamRemoved = Instance.new("BindableEvent")

---------- Local functions ----------
-- Define general functions here

---------- Event functions ----------
-- Functions that are directly connected by events or signals

local function onMapAdded(map: Folder)
	-- Validate dream
	local dreamFolder = map.Parent
	if not (dreamFolder and dreamFolder:GetAttribute("DreamDifficulty")) then
		return
	end

	-- Save dream
	table.insert(storedDreamFolders, dreamFolder)

	-- Event
	DreamMaps.dreamAdded:Fire(dreamFolder)
end

local function onMapRemoved(map: Folder)
	-- Validate dream
	local dreamFolder = map.Parent
	if not (dreamFolder and dreamFolder:GetAttribute("DreamDifficulty")) then
		return
	end

	-- Remove dream
	table.remove(storedDreamFolders, table.find(storedDreamFolders, dreamFolder))

	-- Event
	DreamMaps.dreamRemoved:Fire(dreamFolder)
end

---------- Module functions ----------

function DreamMaps.getAllDreams()
	return storedDreamFolders
end

---------- Set up function ----------
local function initSetUp()
	-- Tags
	local tagged = CollectionService:GetTagged(mapTagName)
	task.defer(function()
		for _, object in tagged do
			onMapAdded(object)
		end
	end)
	CollectionService:GetInstanceAddedSignal(mapTagName):Connect(onMapAdded)
	CollectionService:GetInstanceRemovedSignal(mapTagName):Connect(onMapRemoved)
end

---------- Calling / connecting functions ----------
-- Connect functions to events and signals, then call set up functions

task.defer(initSetUp)

---------- Return module ----------
return DreamMaps

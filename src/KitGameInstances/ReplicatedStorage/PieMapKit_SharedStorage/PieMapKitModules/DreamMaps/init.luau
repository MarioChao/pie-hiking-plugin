--!strict
-- Dream Maps Module


---------- Module ----------
local DreamMaps = {}


---------- Services ----------

local CollectionService = game:GetService("CollectionService")


---------- Types ----------


---------- Instances ----------



---------- Constants ----------

local Constants = {}
Constants.dreamFolderTagName = "DreamFolder"
Constants.mapTagName = "HikeMap"

table.freeze(Constants)


---------- Variables ----------

local storedDreamFolders: {Instance} = {}


---------- Module variables ----------

-- Fires when a new dream folder is stored (tagged)
DreamMaps.dreamAdded = Instance.new("BindableEvent")

-- Fires when a dream folder is removed (untagged)
DreamMaps.dreamRemoved = Instance.new("BindableEvent")


---------- Local functions ----------
-- Define general functions here


----- Dreams -----

local function getIsDreamFolder(object: Instance): boolean
	return object and (object:HasTag(Constants.dreamFolderTagName) or object:GetAttribute("DreamDifficulty") ~= nil)
end


----- Event functions -----
-- Functions that are directly connected by events or signals

local function onMapAdded(map: Folder)
	-- Validate dream
	local dreamFolder = map.Parent
	if not (dreamFolder and getIsDreamFolder(dreamFolder)) then
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
	if not (dreamFolder and getIsDreamFolder(dreamFolder)) then
		return
	end

	-- Remove dream
	table.remove(storedDreamFolders, table.find(storedDreamFolders, dreamFolder))

	-- Event
	DreamMaps.dreamRemoved:Fire(dreamFolder)
end


----- Module functions -----

function DreamMaps.getAllDreams()
	return storedDreamFolders
end


----- Set up function -----
local function initSetUp()
	-- Tags
	local tagged = CollectionService:GetTagged(Constants.mapTagName)
	task.defer(function()
		for _, object in tagged do
			onMapAdded(object)
		end
	end)
	CollectionService:GetInstanceAddedSignal(Constants.mapTagName):Connect(onMapAdded)
	CollectionService:GetInstanceRemovedSignal(Constants.mapTagName):Connect(onMapRemoved)
end


---------- Calling / connecting functions ----------
-- Connect functions to events and signals, then call set up functions

task.defer(initSetUp)


---------- Return module ----------
return DreamMaps

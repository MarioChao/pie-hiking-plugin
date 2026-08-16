--!strict

-- Dream Maps Module


---------- Services ----------

local CollectionService = game:GetService("CollectionService")


---------- Constants ----------

local Constants = {}

Constants.dreamFolderTagName = "DreamFolder"
Constants.mapTagName = "HikeMap"

Constants.dreamAdded_BE = Instance.new("BindableEvent")
Constants.dreamRemoved_BE = Instance.new("BindableEvent")

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.dreamFolder_isStored = {} :: {[Instance]: true?}


---------- Local functions ----------

local getIsDreamFolder

local onMapAdded
local onMapRemoved


----- Dreams -----

getIsDreamFolder = function(object: Instance): boolean
	return object and (object:HasTag(Constants.dreamFolderTagName) or object:GetAttribute("DreamDifficulty") ~= nil)
end


----- Maps -----

onMapAdded = function(map: Instance)
	-- Validate dream
	local dreamFolder = map.Parent
	if not (dreamFolder and getIsDreamFolder(dreamFolder)) then
		return
	end

	-- Store dream
	Globals.dreamFolder_isStored[dreamFolder] = true

	-- Fire event
	Constants.dreamAdded_BE:Fire(dreamFolder)
end

onMapRemoved = function(map: Instance)
	-- Validate dream
	local dreamFolder = map.Parent
	if not (dreamFolder and getIsDreamFolder(dreamFolder)) then
		return
	end

	-- Remove dream
	Globals.dreamFolder_isStored[dreamFolder] = nil

	-- Fire event
	Constants.dreamRemoved_BE:Fire(dreamFolder)
end


----- Main -----

local function main()
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


---------- Calling function ----------

task.defer(main)


---------- Module ----------

local DreamMaps = {}


----- Module fields -----

-- Fires when a new dream folder is stored (tagged)
DreamMaps.dreamAdded = Constants.dreamAdded_BE

-- Fires when a dream folder is removed (untagged)
DreamMaps.dreamRemoved = Constants.dreamRemoved_BE


----- Module functions -----

function DreamMaps.getAllDreams()
	local result = {}
	for dreamFolder, isStored in Globals.dreamFolder_isStored do
		if isStored then
			table.insert(result, dreamFolder)
		end
	end
	return result
end


---------- Return module ----------

table.freeze(DreamMaps)
return DreamMaps

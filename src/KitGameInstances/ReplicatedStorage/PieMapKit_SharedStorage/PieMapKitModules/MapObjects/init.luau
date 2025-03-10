--!strict
-- Map Objects Module

---------- Module ----------
local MapObjects = {}

---------- Services ----------

local CollectionService = game:GetService("CollectionService")

---------- Imports ----------

local BurnBricks = require(script.BurnBricks)
local DamageBricks = require(script.DamageBricks)
local HikeCheckpoints = require(script.HikeCheckpoints)
local PositionTeleporters = require(script.PositionTeleporters)

---------- Types ----------

type ObjectModule = {
	addInstance: (Instance) -> any,
	removeInstance: (Instance) -> any,
}

---------- Variables ----------

local objectTagNames: {[string]: ObjectModule} = {
	["BurnBrick"] = BurnBricks,
	["DamageBrick"] = DamageBricks,
	["HikeCheckpoint"] = HikeCheckpoints,
	["PositionTeleporter"] = PositionTeleporters,
}

---------- Event functions ----------

local function setUpTags()
	for tagName, module in objectTagNames do
		local tagged = CollectionService:GetTagged(tagName)
		task.defer(function()
			for _, object in tagged do
				module.addInstance(object)
			end
		end)
		CollectionService:GetInstanceAddedSignal(tagName):Connect(module.addInstance)
		CollectionService:GetInstanceRemovedSignal(tagName):Connect(module.removeInstance)
	end
end

---------- Set up function ----------
local function initSetUp()
	setUpTags()
end


---------- Calling / connecting functions ----------

initSetUp()

---------- Return module ----------
return 1

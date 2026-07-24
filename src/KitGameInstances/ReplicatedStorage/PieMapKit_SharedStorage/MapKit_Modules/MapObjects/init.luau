--!strict

-- Map Objects Module


---------- Services ----------

local CollectionService = game:GetService("CollectionService")


---------- Imports ----------

local BurnBricks = require(script:WaitForChild("BurnBricks"))
local DamageBricks = require(script:WaitForChild("DamageBricks"))
local HikeCheckpoints = require(script:WaitForChild("HikeCheckpoints"))
local Invisible = require(script:WaitForChild("Invisible"))
local PositionTeleporters = require(script:WaitForChild("PositionTeleporters"))
local MusicZones = require(script:WaitForChild("MusicZones"))
local LightingZones = require(script:WaitForChild("LightingZones"))

local LegacyLightingZones = require(script:WaitForChild("LegacyLightingZones"))
local LegacyMusicZones = require(script:WaitForChild("LegacyMusicZones"))


---------- Types ----------

type ObjectModule = {
	addInstance: (Instance) -> any,
	removeInstance: (Instance) -> any,
}


---------- Constants ----------

local Constants = {}

do
	local objectTag_module: {[string]: ObjectModule} = {
		["BurnBrick"] = BurnBricks,
		["DamageBrick"] = DamageBricks,
		["HikeCheckpoint"] = HikeCheckpoints,
		["PositionTeleporter"] = PositionTeleporters,
		["Invisible"] = Invisible,

		-- Container mechanics
		["MusicZoneConfig"] = MusicZones,
		["LightingZoneConfig"] = LightingZones,
	
		-- Legacy objects
		["MusicZone"] = LegacyMusicZones,
		["LightingZone"] = LegacyLightingZones,
	}
	table.freeze(objectTag_module)
	Constants.objectTag_module = objectTag_module
end

table.freeze(Constants)


---------- Local functions ----------

local setUpTags


----- Set up tags -----

setUpTags = function()
	for tagName, module in Constants.objectTag_module do
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


----- Main -----

local function main()
	setUpTags()
end


---------- Calling function ----------

main()


---------- Return module ----------

return 1

--!strict

-- Collision Groups


---------- Validate container ----------

-- Server script service
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end


---------- Services ----------

local PhysicsService = game:GetService("PhysicsService")


---------- Types ----------

type CollisionGroupData = {
	GroupName: string,
	CollidesWith: {string},
	DoNotCollideWith: {string},
	DoNotCreate: boolean
}


---------- Constants ----------

local Constants = {}

Constants.collisionGroupsTable = {
	{
		GroupName = "Default",
		CollidesWith = {"Default", "LocalPlayer"},
		DoNotCollideWith = {"OtherPlayers", "OnlyCollidePlayer"},
		DoNotCreate = true
	},
	{
		GroupName = "LocalPlayer",
		CollidesWith = {"Default", "OnlyCollidePlayer"},
		DoNotCollideWith = {"LocalPlayer", "OtherPlayers"},
		DoNotCreate = false
	},
	{
		GroupName = "OtherPlayers",
		CollidesWith = {},
		DoNotCollideWith = {"Default", "LocalPlayer", "OtherPlayers", "OnlyCollidePlayer"},
		DoNotCreate = false
	},
	{
		GroupName = "OnlyCollidePlayer",
		CollidesWith = {"LocalPlayer"},
		DoNotCollideWith = {"Default", "OtherPlayers", "OnlyCollidePlayer"},
		DoNotCreate = false
	},
} :: {CollisionGroupData}

table.freeze(Constants)


---------- Local functions ----------

local setUpCollisionGroups


----- Collision groups -----

setUpCollisionGroups = function()
	-- Register groups
	for _, collisionGroupData in Constants.collisionGroupsTable do
		if not collisionGroupData.DoNotCreate then
			PhysicsService:RegisterCollisionGroup(collisionGroupData.GroupName)
		end
	end

	-- Set collidable
	for _, collisionGroupData in Constants.collisionGroupsTable do
		for _, collideWithName in collisionGroupData.CollidesWith do
			PhysicsService:CollisionGroupSetCollidable(collisionGroupData.GroupName, collideWithName, true)
		end
		for _, doNotCollideWithName in collisionGroupData.DoNotCollideWith do
			PhysicsService:CollisionGroupSetCollidable(collisionGroupData.GroupName, doNotCollideWithName, false)
		end
	end
end


----- Main -----

local function main()
	setUpCollisionGroups()
end


---------- Calling function ----------

main()

--!strict
-- Collision Groups Script


---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
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


---------- Variables ----------

local CollisionGroupsTable: {CollisionGroupData} = {
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
	}
}


---------- Local functions ----------

local function setUpCollisionGroups()
	-- Register groups
	for _, collisionGroupData in CollisionGroupsTable do
		if not collisionGroupData.DoNotCreate then
			PhysicsService:RegisterCollisionGroup(collisionGroupData.GroupName)
		end
	end

	-- Set collidable
	for _, collisionGroupData in CollisionGroupsTable do
		for _, collideWithName in collisionGroupData.CollidesWith do
			PhysicsService:CollisionGroupSetCollidable(collisionGroupData.GroupName, collideWithName, true)
		end
		for _, doNotCollideWithName in collisionGroupData.DoNotCollideWith do
			PhysicsService:CollisionGroupSetCollidable(collisionGroupData.GroupName, doNotCollideWithName, false)
		end
	end
end


---------- Calling / connecting functions ----------

setUpCollisionGroups()

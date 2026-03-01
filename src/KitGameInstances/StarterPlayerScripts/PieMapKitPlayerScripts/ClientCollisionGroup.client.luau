--!strict

-- Client Collision Script


---------- Validate container ----------
-- Validate the script's container before running any code

-- For certain client scripts
if not script:FindFirstAncestorWhichIsA("PlayerScripts") then
	return
end


---------- Services ----------

local Players = game:GetService("Players")


---------- Constants ----------

local Constants = {}

Constants.localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() :: Player

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.part_parentConnection = {} :: {[BasePart]: RBXScriptConnection}


---------- Local functions ----------

local getIsDescendantOfPlayerCharacter
local connectUnparentSetDefault
local onOtherCharacterDescendantAdded
local onOtherCharacterAdded
local onOtherPlayerAdded
local onLocalCharacterDescendantAdded
local onLocalCharacterAdded
local onLocalPlayerAdded


----- Unparent -----

getIsDescendantOfPlayerCharacter = function(object: Instance)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			if object:IsDescendantOf(character) then
				return true
			end
		end
	end
	return false
end

connectUnparentSetDefault = function(part: Instance)
	if part:IsA("BasePart") then
		if Globals.part_parentConnection[part] then
			Globals.part_parentConnection[part]:Disconnect()
		end
		Globals.part_parentConnection[part] = part.AncestryChanged:Connect(function()
			if table.find({"LocalPlayer", "OtherPlayers"}, part.CollisionGroup) then
				if not getIsDescendantOfPlayerCharacter(part) then
					part.CollisionGroup = "Default"
					Globals.part_parentConnection[part]:Disconnect()
					Globals.part_parentConnection[part] = nil
				end
			end
		end)
	end
end


----- Other players -----

onOtherCharacterDescendantAdded = function(object: Instance)
	-- Set collision group
	if object:IsA("BasePart") and table.find({"Default", "LocalPlayer"}, object.CollisionGroup) then
		object.CollisionGroup = "OtherPlayers"
		connectUnparentSetDefault(object)
	end
end

onOtherCharacterAdded = function(character: Model)
	-- Current descendant parts
	local children = character:GetDescendants()
	task.defer(function()
		for _, object in children do
			onOtherCharacterDescendantAdded(object)
		end
	end)

	-- Future descendant parts
	character.DescendantAdded:Connect(onOtherCharacterDescendantAdded)
end

onOtherPlayerAdded = function(player: Player)
	-- Set up other players
	local character = player.Character
	if character then
		task.defer(function()
			onOtherCharacterAdded(character)
		end)
	end
	player.CharacterAdded:Connect(onOtherCharacterAdded)
end


------- Local player -----

onLocalCharacterDescendantAdded = function(object: Instance)
	-- Set collision group
	if object:IsA("BasePart") and table.find({"Default", "OtherPlayers"}, object.CollisionGroup) then
		if object.Parent == Constants.localPlayer.Character then
			object.CollisionGroup = "LocalPlayer"
			connectUnparentSetDefault(object)
		else
			object.CollisionGroup = "Default"
		end
	end
end

onLocalCharacterAdded = function(character: Model)
	-- Current descendant parts
	local children = character:GetDescendants()
	task.defer(function()
		for _, object in children do
			onLocalCharacterDescendantAdded(object)
		end
	end)

	-- Future descendant parts
	character.DescendantAdded:Connect(onLocalCharacterDescendantAdded)
end

onLocalPlayerAdded = function()
	-- Set up local player
	local character = Constants.localPlayer.Character
	if character then
		task.defer(function()
			onLocalCharacterAdded(character)
		end)
	end
	Constants.localPlayer.CharacterAdded:Connect(onLocalCharacterAdded)
end


----- Main -----

local function main()
	-- Other players
	local initialPlayers = Players:GetPlayers()
	task.defer(function()
		for _, player in initialPlayers do
			if player ~= Players.LocalPlayer then
				task.defer(function()
					onOtherPlayerAdded(player)
				end)
			end
		end
	end)
	Players.PlayerAdded:Connect(onOtherPlayerAdded)

	-- Local player
	onLocalPlayerAdded()
end


---------- Calling function ----------

main()

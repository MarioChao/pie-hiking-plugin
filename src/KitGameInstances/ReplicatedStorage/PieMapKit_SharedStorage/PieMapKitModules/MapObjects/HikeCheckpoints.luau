--!strict
-- Template Object Module

---------- Module ----------
local Module = {}

---------- Services ----------

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

---------- Types ----------

---------- Instances ----------

---------- Variables ----------

local taggedConnections: {[BasePart]: {RBXScriptConnection}} = {}

local playerCheckpoint: {[Player]: BasePart} = {}

---------- Local functions ----------
-- Define general functions here

local function playCheckpointEffect(part: BasePart)
	local sparkle = Instance.new("Sparkles")
	sparkle.Parent = part
	Debris:AddItem(sparkle, 2)
end

local function onCheckpointTouched(checkpointPart: BasePart, otherPart: BasePart)
	-- Validate player
	local character = otherPart.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not (character and player) then
		return
	end

	-- Validate humanoid alive
	local humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	if not (humanoid and humanoid.Health > 0) then
		return
	end

	-- Validate new checkpoint
	if not (playerCheckpoint[player] ~= checkpointPart) then
		return
	end

	-- Set checkpoint
	playerCheckpoint[player] = checkpointPart

	-- Checkpoint effect
	playCheckpointEffect(checkpointPart)
end

local function setUpObject(part: BasePart)
	-- Set up connections
	local connections = {}
	taggedConnections[part] = connections

	-- Create connections
	table.insert(connections, part.Touched:Connect(function(otherPart: BasePart)
		onCheckpointTouched(part, otherPart)
	end))
end

local function cleanUpObject(part: BasePart)
	-- Disconnect and remove stored connections
	if taggedConnections[part] then
		for _, connection in taggedConnections[part] do
			connection:Disconnect()
		end
		taggedConnections[part] = nil
	end

	-- Remove checkpoints containing part
	for player, checkpoint in playerCheckpoint do
		if part == checkpoint then
			playerCheckpoint[player] = nil
		end
	end
end

local function validateObject(object: Instance)
	return object:IsA("BasePart")
end

---------- Event functions ----------

local function onCharacterAdded(character: Model, player: Player)
	-- Validate existing checkpoint
	local checkpointPart = playerCheckpoint[player]
	if not checkpointPart then
		return
	end

	-- Validate humanoid root part
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart?
	if not humanoidRootPart then
		return
	end

	-- Delay a bit to allow default spawn position
	task.wait(0.1)

	-- Move player to checkpoint
	local checkpointCFrame = checkpointPart.CFrame
	checkpointCFrame += Vector3.new(0, checkpointPart.Size.Y / 2, 0)
	humanoidRootPart:PivotTo(checkpointCFrame)
	-- character:PivotTo(checkpointCFrame)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(character, player)
	end)
end

local function onPlayerRemoving(player: Player)
	playerCheckpoint[player] = nil
end

local function allPlayerEvents()
	local players = Players:GetPlayers()
	task.defer(function()
		for _, player in players do
			onPlayerAdded(player)
		end
	end)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

---------- Module functions ----------

function Module.addInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Validate unique
	if taggedConnections[object] then
		return
	end

	-- Set up object
	setUpObject(object)
end

function Module.removeInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Clean up object
	cleanUpObject(object)
end

---------- Set up function ----------
local function initSetUp()
	if RunService:IsClient() then
		-- For local player
		onPlayerAdded(Players.LocalPlayer)
	elseif RunService:IsServer() then
		-- For all players (not used)
		-- allPlayerEvents()
	end
end

---------- Calling / connecting functions ----------
initSetUp()

---------- Return module ----------
return Module

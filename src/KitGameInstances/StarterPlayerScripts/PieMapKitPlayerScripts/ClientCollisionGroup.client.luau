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


---------- Instances ----------

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() :: Player


---------- Local functions ----------

-- Character collisions

local function onOtherCharacterChildAdded(object: Instance)
	-- Set collision group
	if object:IsA("BasePart") then
		object.CollisionGroup = "OtherPlayers"
	end
end

local function onLocalCharacterChildAdded(object: Instance)
	-- Set collision group
	if object:IsA("BasePart") and not object:FindFirstAncestorWhichIsA("Tool") then
		object.CollisionGroup = "LocalPlayer"
	end
end

local function onOtherCharacterAdded(character: Model)
	-- Look through child parts
	local children = character:GetChildren()
	task.defer(function()
		for _, object in children do
			onOtherCharacterChildAdded(object)
		end
	end)

	-- Listen for future parts
	character.ChildAdded:Connect(onOtherCharacterChildAdded)
end

local function onLocalCharacterAdded(character: Model)
	-- Look through child parts
	local children = character:GetChildren()
	task.defer(function()
		for _, object in children do
			onLocalCharacterChildAdded(object)
		end
	end)

	-- Listen for future parts
	character.ChildAdded:Connect(onLocalCharacterChildAdded)
end

local function onOtherPlayerAdded(player: Player)
	-- Set up other players
	local character = player.Character
	if character then
		task.defer(function()
			onOtherCharacterAdded(character)
		end)
	end
	player.CharacterAdded:Connect(onOtherCharacterAdded)
end

local function setUpLocalPlayer()
	-- Set up local player
	local character = LocalPlayer.Character
	if character then
		task.defer(function()
			onLocalCharacterAdded(character)
		end)
	end
	LocalPlayer.CharacterAdded:Connect(onLocalCharacterAdded)
end

local function setUpPlayerCollisions()
	-- Local player
	setUpLocalPlayer()

	-- Other players
	task.defer(function()
		for _, player in Players:GetPlayers() do
			if player ~= Players.LocalPlayer then
				task.defer(function()
					onOtherPlayerAdded(player)
				end)
			end
		end
	end)
	Players.PlayerAdded:Connect(onOtherPlayerAdded)
end


---------- Calling / connecting functions ----------

setUpPlayerCollisions()

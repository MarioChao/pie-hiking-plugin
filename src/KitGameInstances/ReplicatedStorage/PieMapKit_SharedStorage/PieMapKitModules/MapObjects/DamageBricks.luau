--!strict
-- Damage Bricks Module


---------- Module ----------
local Module = {}


---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PieMapKit_SharedStorage = script.Parent.Parent.Parent


---------- Types ----------

type DamageBrickAttributes = {
	Damage: number,
	DamagesNpc: boolean,
	DamagesPlayer: boolean,
}


---------- Instances ----------

local PieMapKitEvents = PieMapKit_SharedStorage:WaitForChild("PieMapKitEvents")
local DamageBindable = PieMapKitEvents.DamageBindable
local DamageRemote = PieMapKitEvents.DamageRemote


---------- Variables ----------

local taggedConnections: {[BasePart]: {RBXScriptConnection}} = {}


---------- Helper functions ----------

-- Get the part's parent, checking if it is a character model with a `Humanoid`
local function getAndValidateCharacterFromPart(part: BasePart): Model?
	-- Validate part
	if not part:IsA("BasePart") then
		return nil
	end

	-- Validate character
	local character = part.Parent
	if not (character and character:IsA("Model")) then
		return nil
	end

	-- Validate humanoid
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return nil
	end

	-- Return
	return character
end


---------- Local functions ----------
-- Define general functions here

local function _damagePlayerClient(amount: number)
	-- Fire event to deal damage on server
	DamageRemote:FireServer("DamagePlayer", amount)
end

local function _damageNpcServer(character: Model, amount: number)
	-- Fire event
	DamageBindable:Fire("DamageNpc", character, amount)
end

local function damagePlayer(player: Player, amount: number)
	-- Validate client environment
	if not RunService:IsClient() then
		return
	end

	-- Validate player
	if player ~= Players.LocalPlayer then
		return
	end

	-- Fire damage event
	_damagePlayerClient(amount)
end

local function damageNpc(character: Model, amount: number)
	-- Validate server environment
	if not RunService:IsServer() then
		return
	end

	-- Fire damage event
	_damageNpcServer(character, amount)
end

local function onDamageBrickTouched(brickAttributes: DamageBrickAttributes, otherPart: BasePart)
	-- Validate character
	local character = getAndValidateCharacterFromPart(otherPart)
	if not character then
		return
	end

	-- Check player or Npc
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		-- Validate configuration
		if not brickAttributes["DamagesPlayer"] then
			return
		end

		-- Damage
		damagePlayer(player, brickAttributes["Damage"])
	else
		-- Validate configuration
		if not brickAttributes["DamagesNpc"] then
			return
		end

		-- Damage
		damageNpc(character, brickAttributes["Damage"])
	end
end

local function setUpObject(part: BasePart)
	-- Get attributes
	local attributes = {
		Damage = part:GetAttribute("Damage"),
		DamagesPlayer = part:GetAttribute("DamagesPlayer"),
		DamagesNpc = part:GetAttribute("DamagesNpc"),
	}

	-- Set up connections
	local connections = {}
	taggedConnections[part] = connections

	-- Create connections
	table.insert(connections, part.Touched:Connect(function(otherPart: BasePart)
		onDamageBrickTouched(attributes, otherPart)
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
end

local function validateObject(object: Instance)
	return object:IsA("BasePart")
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


---------- Return module ----------
return Module

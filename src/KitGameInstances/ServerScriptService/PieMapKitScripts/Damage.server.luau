--!strict
-- Damage Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services----------

local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")

local PieMapKit_SharedStorage = ReplicatedStorage:FindFirstChild("PieMapKit_SharedStorage")

---------- Instances ----------

local PieMapKitEvents = PieMapKit_SharedStorage.PieMapKitEvents
local DamageBindable = PieMapKitEvents.DamageBindable
local DamageRemote = PieMapKitEvents.DamageRemote

---------- Variables ----------

local characterThrottle: {[Player]: boolean} = {}

---------- Local functions ----------

local function onDamagePlayer(player: Player, amount: number)
	-- Validate positive
	if amount < 0 then
		return
	end

	-- Validate humanoid
	local character = player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	-- Validate throttle
	if characterThrottle[character] then
		return
	end
	characterThrottle[character] = true
	task.defer(function()
		task.wait(0.2)
		characterThrottle[character] = nil
	end)

	-- Deal damage
	humanoid:TakeDamage(amount)
end

local function onDamageNpc(character: Model, amount: number)
	-- Validate humanoid
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	-- Deal damage
	humanoid:TakeDamage(amount)
end

---------- Event functions ----------

local function onDamageBindableEvent(action: string, ...)
	if action == "DamagePlayer" then
		onDamagePlayer(...)
	elseif action == "DamageNpc" then
		onDamageNpc(...)
	end
end

local function onDamageServerEvent(caller: Player, action: string, ...)
	if action == "DamagePlayer" then
		onDamagePlayer(caller, ...)
	end
end

---------- Calling / connecting functions ----------

DamageBindable.Event:Connect(onDamageBindableEvent)
DamageRemote.OnServerEvent:Connect(onDamageServerEvent)

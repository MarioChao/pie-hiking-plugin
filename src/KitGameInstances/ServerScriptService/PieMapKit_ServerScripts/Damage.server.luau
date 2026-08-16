--!strict

-- Damage


---------- Validate container ----------

-- Server script service
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Constants ----------

local Constants = {}

Constants.defaultDamageThrottle = 0.2

do
	local PieMapKit_SharedStorage = ReplicatedStorage:FindFirstChild("PieMapKit_SharedStorage")
	local MapKit_Events = PieMapKit_SharedStorage.MapKit_Events
	Constants.damageBindable = MapKit_Events.DamageBindable
	Constants.damageRemote = MapKit_Events.DamageRemote
end

table.freeze(Constants)


---------- Globals ----------

local characterThrottle: {[Model]: boolean} = {}


---------- Local functions ----------

local onDamagePlayer
local onDamageNpc

local onDamageBindableEvent
local onDamageServerEvent


----- Damage -----

onDamagePlayer = function(player: Player, amount: number)
	-- Validate positive
	if amount < 0 then
		return
	end

	-- Validate humanoid
	local character = player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not (character and humanoid) then
		return
	end

	-- Validate throttle
	if characterThrottle[character] then
		return
	end
	characterThrottle[character] = true
	task.defer(function()
		task.wait(Constants.defaultDamageThrottle)
		characterThrottle[character] = nil
	end)

	-- Deal damage
	humanoid:TakeDamage(amount)
end

onDamageNpc = function(character: Model, amount: number)
	-- Validate humanoid
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	-- Deal damage
	humanoid:TakeDamage(amount)
end


----- Damage events -----

onDamageBindableEvent = function(action: string, ...)
	if action == "DamagePlayer" then
		onDamagePlayer(...)
	elseif action == "DamageNpc" then
		onDamageNpc(...)
	end
end

onDamageServerEvent = function(caller: Player, action: string, ...)
	if action == "DamagePlayer" then
		onDamagePlayer(caller, ...)
	end
end


----- Main -----

local function main()
	Constants.damageBindable.Event:Connect(onDamageBindableEvent)
	Constants.damageRemote.OnServerEvent:Connect(onDamageServerEvent)
end


---------- Calling function ----------

main()

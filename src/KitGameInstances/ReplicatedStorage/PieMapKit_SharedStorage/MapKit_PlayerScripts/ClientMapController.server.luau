--!strict

-- Client Map Controller


---------- Validate container ----------

-- Replicated storage
if not script:FindFirstAncestorWhichIsA("ReplicatedStorage") then
	return
end


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local PieMapKit_SharedStorage = ReplicatedStorage:WaitForChild("PieMapKit_SharedStorage")

local MapKit_Modules = PieMapKit_SharedStorage:WaitForChild("MapKit_Modules")
require(MapKit_Modules.MapObjects)


---------- Constants ----------

local Constants = {}

do
	local MapKit_Events = PieMapKit_SharedStorage:WaitForChild("MapKit_Events")
	Constants.loadDreamRemote = MapKit_Events.LoadDreamRemote
end

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.dreamFolder_clientMap = {} :: {[Instance]: Instance}


---------- Local functions ----------

local clearDream
local loadClientDream
local unloadDream

local onLoadDreamClientEvent


----- Dreams -----

clearDream = function(dreamFolder: Instance)
	if Globals.dreamFolder_clientMap[dreamFolder] then
		Globals.dreamFolder_clientMap[dreamFolder]:Destroy()
		Globals.dreamFolder_clientMap[dreamFolder] = nil
	end
end

loadClientDream = function(dreamFolder: Instance, mapFolder: Instance)
	-- Validate client dream
	if not dreamFolder:GetAttribute("IsClientMap") then
		return
	end

	-- Clear previous instance of the same map
	clearDream(dreamFolder)

	-- Clone a new client-sided map
	local clientMap = mapFolder:Clone()
	Globals.dreamFolder_clientMap[dreamFolder] = clientMap

	-- Load map
	clientMap.Parent = workspace
end

unloadDream = function(dreamFolder: Instance)
	-- Clear the client map of the dream
	clearDream(dreamFolder)
end


----- Event functions -----

onLoadDreamClientEvent = function(action: string, ...)
	if action == "LoadClientDream" then
		loadClientDream(...)
	elseif action == "UnloadDream" then
		unloadDream(...)
	end
end


----- Main -----

local function main()
	Constants.loadDreamRemote.OnClientEvent:Connect(onLoadDreamClientEvent)
end


---------- Calling function ----------

main()

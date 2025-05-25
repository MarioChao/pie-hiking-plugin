--!strict
-- Client Map Controller Script


---------- Validate container ----------
-- Validate the script's container before running any code

-- For certain client scripts
if not script:FindFirstAncestorWhichIsA("PlayerScripts") then
	return
end


---------- Services ----------

local Debris = game:GetService("Debris")
local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")

local PieMapKit_SharedStorage = ReplicatedStorage:WaitForChild("PieMapKit_SharedStorage")


---------- Imports ----------

local PieMapKitModules = PieMapKit_SharedStorage:WaitForChild("PieMapKitModules")
require(PieMapKitModules.MapObjects)


---------- Types ----------


---------- Instances ----------

local PieMapKitEvents = PieMapKit_SharedStorage:WaitForChild("PieMapKitEvents")
local LoadDreamRemote = PieMapKitEvents.LoadDreamRemote


---------- Variables ----------

local clientMapFolders: {[Instance]: Folder} = {}


---------- Local functions ----------
-- Define general functions here

local function clearDream(dreamFolder: Instance)
	if clientMapFolders[dreamFolder] then
		Debris:AddItem(clientMapFolders[dreamFolder], 0)
		clientMapFolders[dreamFolder] = nil
	end
end

local function loadClientDream(dreamFolder: Instance, mapFolder: Folder)
	-- Validate client dream
	if not dreamFolder:GetAttribute("IsClientMap") then
		return
	end

	-- Clear previous instance of the same map
	clearDream(dreamFolder)

	-- Clone a new client-sided map
	local clientMap = mapFolder:Clone()
	clientMapFolders[dreamFolder] = clientMap

	-- Load map
	clientMap.Parent = workspace
end

local function unloadDream(dreamFolder: Instance)
	-- Clear the client map of the dream
	clearDream(dreamFolder)
end


---------- Event functions ----------
-- Functions that are directly connected by events or signals

local function onLoadDreamClientEvent(action: string, ...)
	if action == "LoadClientDream" then
		loadClientDream(...)
	elseif action == "UnloadDream" then
		unloadDream(...)
	end
end


---------- Calling / connecting functions ----------
-- Connect functions to events and signals, then call set up functions

LoadDreamRemote.OnClientEvent:Connect(onLoadDreamClientEvent)

--!strict
-- Map Kit Module


---------- Module ----------
local Module = {}


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")


---------- Instances ----------

local PluginFolder = script.Parent.Parent.Parent

local KitGameInstances = PluginFolder.KitGameInstances
local PieHikingMapKit: Folder


---------- Local functions ----------

local function removeDupes(parent: Instance, childName: string)
	while true do
		local dupe = parent:FindFirstChild(childName)
		if not dupe then
			break
		end
		dupe.Parent = nil
	end
end

local function enableDescendantScripts(parent: Instance)
	for _, object in parent:GetDescendants() do
		-- Validate script
		if not object:IsA("Script") then
			continue
		end

		-- Validate enabled property
		if not object:GetAttribute("Enabled") then
			continue
		end

		-- Enable script and remove property
		object.Enabled = true
		object:SetAttribute("Enabled", nil)
	end
end

local function setUpMapKitContainers(): {Instance}
	local addedInstances = {}

	for _, object in KitGameInstances.ReplicatedStorage:GetChildren() do
		removeDupes(ReplicatedStorage, object.Name)
		local newObject = object:Clone()
		enableDescendantScripts(newObject)
		newObject.Parent = ReplicatedStorage
		table.insert(addedInstances, newObject)
	end
	for _, object in KitGameInstances.ServerScriptService:GetChildren() do
		removeDupes(ServerScriptService, object.Name)
		local newObject = object:Clone()
		enableDescendantScripts(newObject)
		newObject.Parent = ServerScriptService
		table.insert(addedInstances, newObject)
	end
	for _, object in KitGameInstances.StarterPlayerScripts:GetChildren() do
		removeDupes(StarterPlayer.StarterPlayerScripts, object.Name)
		local newObject = object:Clone()
		enableDescendantScripts(newObject)
		newObject.Parent = StarterPlayer.StarterPlayerScripts
		table.insert(addedInstances, newObject)
	end

	return addedInstances
end

local function setUpMapKitProperties()
	warn("If you haven't, please enable TouchesUseCollisionGroups in Workspace!")
end

local function insertMapKit(): {Instance}
	local newKit: typeof(PieHikingMapKit) = PieHikingMapKit:Clone()
	newKit.Parent = workspace

	return {newKit}
end

local function refreshMapKit()
	PieHikingMapKit = game:GetObjects("rbxassetid://18722872073")[1]
	PieHikingMapKit.Name = `Pie Hiking Map Kit (from plugin)`
end


---------- Module functions ----------

function Module.setUp()
	local addedInstances = setUpMapKitContainers()
	Selection:Set(addedInstances)
	setUpMapKitProperties()
end

function Module.insert()
	refreshMapKit()
	local addedInstances = insertMapKit()
	Selection:Set(addedInstances)
end


---------- Return module ----------
return Module

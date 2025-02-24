--!strict
-- Pie Tool Module

---------- Module ----------
local Module = {}

---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")

---------- Instances ----------

local PluginFolder = script.Parent.Parent.Parent

local HeartPie: Tool

local DevPackages = PluginFolder:FindFirstChild("DevPackages")
if DevPackages then
	-- This is for type-checking with Roblox LSP on VSCode
	local DevPackagesIndex = DevPackages._Index
	HeartPie = DevPackagesIndex["mariochao_heart-pie@1.0.0"]["heart-pie"]
end

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

local function setUpPieToolContainers(): {Instance}
	local addedInstances = {}

	local HeartPie_ContainerScripts = HeartPie:FindFirstChild("ContainerScripts (see ReadMe)")
	for _, object in HeartPie_ContainerScripts.ReplicatedStorage:GetChildren() do
		removeDupes(ReplicatedStorage, object.Name)
		local newObject = object:Clone()
		newObject.Parent = ReplicatedStorage
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.ServerScriptService:GetChildren() do
		removeDupes(ServerScriptService, object.Name)
		local newObject = object:Clone()
		newObject.Parent = ServerScriptService
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.ServerStorage:GetChildren() do
		removeDupes(ServerStorage, object.Name)
		local newObject = object:Clone()
		newObject.Parent = ServerStorage
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.StarterPlayerScripts:GetChildren() do
		removeDupes(StarterPlayer.StarterPlayerScripts, object.Name)
		local newObject = object:Clone()
		newObject.Parent = StarterPlayer.StarterPlayerScripts
		table.insert(addedInstances, newObject)
	end

	return addedInstances
end

local function insertPieTool(): {Instance}
	if StarterPack:FindFirstChild(HeartPie.Name) then
		warn(`A {HeartPie.Name} already exists in StarterPack.`)
		return {}
	end

	local newHeartPie: typeof(HeartPie) = HeartPie:Clone()
	newHeartPie:SetAttribute("IsClientPieType", true)
	newHeartPie.Parent = StarterPack

	return {newHeartPie}
end

local function refreshPieTool()
	HeartPie = game:GetObjects("rbxassetid://18174104986")[1]
	HeartPie.Name = `Heart Pie (from plugin)`
end

---------- Module functions ----------

function Module.setUp()
	refreshPieTool()
	local addedInstances = setUpPieToolContainers()
	Selection:Set(addedInstances)
end

function Module.insert()
	refreshPieTool()
	local addedInstances = insertPieTool()
	Selection:Set(addedInstances)
end

---------- Return module ----------
return Module

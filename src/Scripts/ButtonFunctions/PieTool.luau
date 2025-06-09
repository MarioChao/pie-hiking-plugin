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

local HeartPie_ContainerScripts

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

local function replaceIfNotFound(parent: Instance, child: Instance)
	local addedInstance = nil
	if not parent:FindFirstChild(child.Name) then
		local newObject = child:Clone()
		newObject.Parent = parent
		addedInstance = newObject
	end
	return addedInstance
end

local function replaceWithNew(parent: Instance, child: Instance)
	removeDupes(parent, child.Name)
	local newObject = child:Clone()
	newObject.Parent = parent
	return newObject
end


---------- Set up functions ----------

local function setUpPieToolContainers(): {Instance}
	local addedInstances = {}

	local canSetUp = (
		(HeartPie_ContainerScripts and HeartPie_ContainerScripts:IsA("Folder"))
		and HeartPie_ContainerScripts:FindFirstChild("ReplicatedStorage")
	)
	if not canSetUp then
		warn("Set up error: can't set up heart pie!")
	end

	for _, object in HeartPie_ContainerScripts.ReplicatedStorage:GetChildren() do
		-- Special case
		if object.Name == "PieHikingModules" then
			table.insert(addedInstances, replaceIfNotFound(ReplicatedStorage, object))
			for _, object_2 in object:GetChildren() do
				-- Special case
				if object_2.Name == "PieHitEffects" or object_2.Name == "EffectsList" then
					local newReplaced = replaceIfNotFound(ReplicatedStorage[object.Name], object_2)
					table.insert(addedInstances, newReplaced)
					continue
				end

				local newObject = replaceWithNew(ReplicatedStorage[object.Name], object_2)
				table.insert(addedInstances, newObject)
			end
			continue
		end
		local newObject = replaceWithNew(ReplicatedStorage, object)
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.ServerScriptService:GetChildren() do
		local newObject = replaceWithNew(ServerScriptService, object)
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.ServerStorage:GetChildren() do
		-- Special case
		if object.Name == "PieHikingServerStorage" then
			table.insert(addedInstances, replaceIfNotFound(ServerStorage, object))
			for _, object_2 in object:GetChildren() do
				-- Special case
				if object_2.Name == "PieSkins" or object_2.Name == "PieSkinConditions" then
					local newReplaced = replaceIfNotFound(ServerStorage[object.Name], object_2)
					table.insert(addedInstances, newReplaced)
					continue
				end

				local newObject = replaceWithNew(ServerStorage[object.Name], object_2)
				table.insert(addedInstances, newObject)
			end
			continue
		end

		local newObject = replaceWithNew(ServerStorage, object)
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.StarterPlayerScripts:GetChildren() do
		local newObject = replaceWithNew(StarterPlayer.StarterPlayerScripts, object)
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

	HeartPie_ContainerScripts = HeartPie:FindFirstChild("ContainerScripts (see ReadMe)") or HeartPie:FindFirstChild("ContainerScripts")
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

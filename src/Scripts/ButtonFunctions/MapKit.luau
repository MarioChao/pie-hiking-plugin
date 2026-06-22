--!strict

-- Map Kit


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")


---------- Types ----------

type FilePath = {[string]: FilePath}


---------- Constants ----------

local Constants = {}

Constants.pluginFolder = script.Parent.Parent.Parent
Constants.kitGameInstances = Constants.pluginFolder.KitGameInstances

table.freeze(Constants)


---------- Local functions ----------

local removeDupes
local replaceIfNotFound
local replaceWithNew
local cloneReparentRecursive

local enableDescendantScripts
local setUpMapKitContainers
local setUpMapKitProperties
local insertMapKit
local getRefreshedMapKit


----- Replacement -----

removeDupes = function(parent: Instance, childName: string)
	while true do
		local dupe = parent:FindFirstChild(childName)
		if not dupe then
			break
		end
		dupe.Parent = nil
	end
end

replaceIfNotFound = function(parent: Instance, child: Instance)
	local addedInstance = nil
	if not parent:FindFirstChild(child.Name) then
		local newObject = child:Clone()
		newObject.Parent = parent
		addedInstance = newObject
	end
	return addedInstance
end

replaceWithNew = function(parent: Instance, child: Instance)
	removeDupes(parent, child.Name)
	local newObject = child:Clone()
	newObject.Parent = parent
	return newObject
end

cloneReparentRecursive = function(oldParent: Instance, newParent: Instance, doNotReplacePaths: FilePath): {Instance}
	local addedInstances = {}
	for _, child in oldParent:GetChildren() do
		-- Check do not replace
		if doNotReplacePaths[child.Name] then
			-- Replace if not found
			local replacedObject = replaceIfNotFound(newParent, child)
			table.insert(addedInstances, replacedObject)

			-- Reparent recursive
			local newParentChild = newParent:FindFirstChild(child.Name) or replacedObject
			local tempInstances = cloneReparentRecursive(child, newParentChild, doNotReplacePaths[child.Name])
			table.move(tempInstances, 1, #tempInstances, #addedInstances + 1, addedInstances)
			continue
		end

		-- Replace
		table.insert(addedInstances, replaceWithNew(newParent, child))
	end
	return addedInstances
end


----- Set up -----

enableDescendantScripts = function(parent: Instance)
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

setUpMapKitContainers = function(): {Instance}
	local addedInstances = {}
	local tempInstances: {Instance}

	-- Clone container scripts
	local containerScripts = Constants.kitGameInstances:Clone()

	-- Replicated storage
	tempInstances = cloneReparentRecursive(containerScripts.ReplicatedStorage, ReplicatedStorage, {
		PieMapKit_SharedStorage = {
			Custom_DefaultMusicSound = {},
		},
	})
	table.move(tempInstances, 1, #tempInstances, #addedInstances + 1, addedInstances)
	for _, object in tempInstances do
		enableDescendantScripts(object)
	end

	-- Server script service
	tempInstances = cloneReparentRecursive(containerScripts.ServerScriptService, ServerScriptService, {})
	table.move(tempInstances, 1, #tempInstances, #addedInstances + 1, addedInstances)
	for _, object in tempInstances do
		enableDescendantScripts(object)
	end

	return addedInstances
end

setUpMapKitProperties = function()
	warn("If you haven't, please enable TouchesUseCollisionGroups in Workspace!")
end

insertMapKit = function(mapKit: Instance): {Instance}
	local newKit = mapKit:Clone()
	newKit.Parent = workspace

	return {newKit}
end

getRefreshedMapKit = function()
	local mapKit = game:GetObjects("rbxassetid://18722872073")[1]
	mapKit.Name = `Pie Hiking Map Kit (from plugin)`
	return mapKit
end


---------- Module ----------

local Module = {}


----- Module functions -----

function Module.setUp()
	local addedInstances = setUpMapKitContainers()
	Selection:Set(addedInstances)
	setUpMapKitProperties()
end

function Module.insert()
	local mapKit = getRefreshedMapKit()
	local addedInstances = insertMapKit(mapKit)
	Selection:Set(addedInstances)
end


---------- Return module ----------

table.freeze(Module)
return Module

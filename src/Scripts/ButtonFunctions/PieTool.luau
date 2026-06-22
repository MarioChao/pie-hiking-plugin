--!strict

-- Pie Tool


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")


---------- Types ----------

type FilePath = {[string]: FilePath}


---------- Constants ----------

local Constants = {}

Constants.pluginFolder = script.Parent.Parent.Parent

Constants.assets = Constants.pluginFolder:FindFirstChild("Assets")
Constants.heartPie_moduleFolder = Constants.assets.HeartPie_Module
Constants._heartPieModule = Constants.heartPie_moduleFolder.MainModule
Constants.heartPie_package = Constants._heartPieModule.HeartPie_Package
Constants.heartPie_tool = Constants.heartPie_package.HeartPie
Constants.containerScripts = Constants.heartPie_package.ContainerScripts
Constants.containerSetUp = Constants.heartPie_package.ContainerSetUp

Constants.heartPie_customKit = Constants.assets.HeartPie_CustomKit

Constants.strings = {
	customKitName = "HeartPie_CustomKit",
	moduleFolderName = "HeartPie_Module",
	packageName = "HeartPie_Package",
	classicPieName = "Classic Heart Pie (from plugin)",
	beginnerPieName = "Beginner Heart Pie (from plugin)",
}

table.freeze(Constants.strings)
table.freeze(Constants)


---------- Local functions ----------

local removeDupes
local replaceIfNotFound
local replaceWithNew
local cloneReparentRecursive

local setUpPieToolContainers

local insertPieModuleFolder
local insertPieCustomKit
local insertClassicPieTool
local insertBeginnerPieTool


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

setUpPieToolContainers = function(): {Instance}
	local addedInstances = {}
	local tempInstances: {Instance}
	local defaultContainerScripts = Constants.containerScripts

	-- Validate container scripts
	local canSetUp = (
		(defaultContainerScripts and defaultContainerScripts:IsA("Folder"))
		and defaultContainerScripts:FindFirstChild("ReplicatedStorage")
	)
	if not canSetUp then
		warn("Set up error: can't set up heart pie!")
		return {}
	end

	-- Clone container scripts
	local containerScripts = defaultContainerScripts:Clone()

	-- Replicated storage
	tempInstances = cloneReparentRecursive(containerScripts.ReplicatedStorage, ReplicatedStorage, {
		PieHiking_SharedStorage = {
			EffectModules = {
				Presets = {
					CustomHitEffectsObjectValue = {},
				},
			},
			SoundModules = {
				Presets = {
					CustomSoundEffectsObjectValue = {},
				},
			},
		},
	})
	table.move(tempInstances, 1, #tempInstances, #addedInstances + 1, addedInstances)

	-- Server script service
	tempInstances = cloneReparentRecursive(containerScripts.ServerScriptService, ServerScriptService, {
		PieHiking_ServerScripts = {
			SkinModules = {
				Presets = {
					CustomConditionalPieSkinsFolderObjectValue = {},
					CustomStarterPieSkinsFolderObjectValue = {},
					CustomPieSkinConditionsObjectValue = {},
				},
			},
		},
	})
	table.move(tempInstances, 1, #tempInstances, #addedInstances + 1, addedInstances)

	return addedInstances
end


----- Insert -----

insertPieModuleFolder = function(): {Instance}
	if ServerStorage:FindFirstChild(Constants.strings.moduleFolderName) then
		warn(`A '{Constants.strings.moduleFolderName}' already exists in ServerStorage.`)
		return {}
	end

	local newModuleFolder = Constants.heartPie_moduleFolder:Clone()
	newModuleFolder.Name = Constants.strings.moduleFolderName
	newModuleFolder.Parent = ServerStorage

	return {newModuleFolder}
end

insertPieCustomKit = function(): {Instance}
	if workspace:FindFirstChild(Constants.strings.customKitName) then
		warn(`A '{Constants.strings.customKitName}' already exists in Workspace.`)
		return {}
	end

	local newCustomKit = Constants.heartPie_customKit:Clone()
	newCustomKit.Name = Constants.strings.customKitName
	newCustomKit.Parent = workspace

	return {newCustomKit}
end

insertClassicPieTool = function(): {Instance}
	if StarterPack:FindFirstChild(Constants.strings.classicPieName) then
		warn(`A '{Constants.strings.classicPieName}' already exists in StarterPack.`)
		return {}
	end

	local newHPMModule = Constants._heartPieModule:Clone()

	local newHeartPie = newHPMModule.HeartPie_Package.HeartPie:Clone()
	newHeartPie.Name = Constants.strings.classicPieName
	newHeartPie.Parent = StarterPack

	return {newHeartPie}
end

insertBeginnerPieTool = function(): {Instance}
	if StarterPack:FindFirstChild(Constants.strings.beginnerPieName) then
		warn(`A '{Constants.strings.beginnerPieName}' already exists in StarterPack.`)
		return {}
	end

	local newHPMModule = Constants._heartPieModule:Clone()
	local hpm = require(newHPMModule) :: any
	local toolConfig = hpm.getToolConfig()
	toolConfig:SetAttribute("CanCollideThrower", false)
	toolConfig:SetAttribute("LaunchOffsetStuds", 0)
	toolConfig:SetAttribute("LaunchVelocity", 95)

	local newHeartPie = newHPMModule.HeartPie_Package.HeartPie:Clone()
	newHeartPie.Name = Constants.strings.beginnerPieName
	newHeartPie:SetAttribute("CanCollideThrower", false)
	newHeartPie:SetAttribute("LaunchOffsetStuds", 0)
	newHeartPie:SetAttribute("LaunchVelocity", 95)
	newHeartPie.Parent = StarterPack

	return {newHeartPie}
end


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.insertModuleFolder()
	local addedInstances = insertPieModuleFolder()
	Selection:Set(addedInstances)
end

function Module.insertCustomKit()
	local addedInstances = insertPieCustomKit()
	Selection:Set(addedInstances)
end

function Module.setUpContainerScripts()
	local addedInstances = setUpPieToolContainers()
	Selection:Set(addedInstances)
end

function Module.insertClassic()
	local addedInstances = insertClassicPieTool()
	Selection:Set(addedInstances)
end

function Module.insertBeginner()
	local addedInstances = insertBeginnerPieTool()
	Selection:Set(addedInstances)
end


---------- Return module ----------

table.freeze(Module)
return Module

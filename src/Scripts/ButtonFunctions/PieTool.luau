--!strict

-- Pie Tool Module


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")


---------- Constants ----------

local Constants = {}

Constants.pluginFolder = script.Parent.Parent.Parent

Constants.assets = Constants.pluginFolder:FindFirstChild("Assets")
Constants.heartPie_folder = Constants.assets.HeartPie_Package
Constants.heartPie_tool = Constants.heartPie_folder.HeartPie
Constants.containerScripts = Constants.heartPie_folder["ContainerScripts (see ReadMe)"]
Constants.containerSetUp = Constants.heartPie_folder.ContainerSetUp

Constants.strings = {
	packageName = "HeartPie_Package",
	classicPieName = "Classic Heart Pie (from plugin)",
	beginnerPieName = "Beginner Heart Pie (from plugin)",
}

table.freeze(Constants.strings)
table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.heartPie_tool = Constants.heartPie_tool:Clone()
Globals.containerScripts = Constants.containerScripts:Clone()


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

local function insertPiePackage(): {Instance}
	if ServerStorage:FindFirstChild(Constants.strings.packageName) then
		warn(`A {Constants.strings.packageName} already exists in ServerStorage.`)
		return {}
	end

	local newPackageFolder = Constants.heartPie_folder:Clone()
	newPackageFolder.Name = Constants.strings.packageName
	newPackageFolder.Parent = ServerStorage

	return {newPackageFolder}
end

local function setUpPieToolContainers(): {Instance}
	local addedInstances = {}

	local canSetUp = (
		(Globals.containerScripts and Globals.containerScripts:IsA("Folder"))
		and Globals.containerScripts:FindFirstChild("ReplicatedStorage")
	)
	if not canSetUp then
		warn("Set up error: can't set up heart pie!")
	end

	for _, object in Globals.containerScripts.ReplicatedStorage:GetChildren() do
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
	for _, object in Globals.containerScripts.ServerScriptService:GetChildren() do
		local newObject = replaceWithNew(ServerScriptService, object)
		table.insert(addedInstances, newObject)
	end
	for _, object in Globals.containerScripts.ServerStorage:GetChildren() do
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

	return addedInstances
end

local function insertClassicPieTool(): {Instance}
	if StarterPack:FindFirstChild(Constants.strings.classicPieName) then
		warn(`A {Constants.strings.classicPieName} already exists in StarterPack.`)
		return {}
	end

	local newHeartPie = Globals.heartPie_tool:Clone()
	newHeartPie.Name = Constants.strings.classicPieName
	newHeartPie.Parent = StarterPack

	return {newHeartPie}
end

local function insertBeginnerPieTool(): {Instance}
	if StarterPack:FindFirstChild(Constants.strings.beginnerPieName) then
		warn(`A {Constants.strings.beginnerPieName} already exists in StarterPack.`)
		return {}
	end

	local newHeartPie = Globals.heartPie_tool:Clone()
	newHeartPie.Name = Constants.strings.beginnerPieName
	newHeartPie:SetAttribute("CanCollideThrower", false)
	newHeartPie:SetAttribute("LaunchOffsetStuds", 0)
	newHeartPie:SetAttribute("LaunchVelocity", 95)
	newHeartPie.Parent = StarterPack

	return {newHeartPie}
end

local function refreshPieTool()
	Globals.heartPie_tool:Destroy()
	Globals.heartPie_tool = Constants.heartPie_tool:Clone()

	Globals.containerScripts:Destroy()
	Globals.containerScripts = Constants.containerScripts:Clone()
end


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.insertPackage()
	refreshPieTool()
	local addedInstances = insertPiePackage()
	Selection:Set(addedInstances)
end

function Module.setUp()
	refreshPieTool()
	local addedInstances = setUpPieToolContainers()
	Selection:Set(addedInstances)
end

function Module.insertClassic()
	refreshPieTool()
	local addedInstances = insertClassicPieTool()
	Selection:Set(addedInstances)
end

function Module.insertBeginner()
	refreshPieTool()
	local addedInstances = insertBeginnerPieTool()
	Selection:Set(addedInstances)
end


---------- Return module ----------

table.freeze(Module)
return Module

--!strict
-- Template Object Container Module
-- For tagged containers


---------- Module ----------
local Module = {}


---------- Services ----------

local ReplicatedStorage = script.Parent.Parent.Parent or game:GetService("ReplicatedStorage")


---------- Types ----------

type ObjectConnections = {[Instance]: {RBXScriptConnection}}


---------- Instances ----------


---------- Variables ----------

local containerName1 = ""
local containerName2 = ""

local taggedContainerConnections: {[Instance]: ObjectConnections} = {}


---------- Helper functions ----------

local function createDefault<K, V>(table: {[K]: V}, key: K, default: V)
	if not table[key] then
		table[key] = default
	end
end


---------- Local functions ----------
-- Define general functions here

-- For subcontainer 1

local function setUpChildObject1(container: Instance, part: BasePart)
	-- Get container connections
	local objectConnections = taggedContainerConnections[container]

	-- Set up connections
	local connections = {}
	objectConnections[part] = connections

	-- Create connections
	table.insert(connections, part.Touched:Connect(function(otherPart: BasePart)
	end))
end

local function onChildObjectAdded1(container: Instance, child: Instance)
	-- Validate child
	if not child:IsA("BasePart") then
		return
	end

	-- Get container connections
	local objectConnections = taggedContainerConnections[container]

	-- Validate unique
	if objectConnections[child] then
		return
	end

	-- Set up child
	setUpChildObject1(container, child)
end

local function cleanUpChildObject1(container: Instance, part: BasePart)
	-- Get container connections
	local objectConnections = taggedContainerConnections[container]

	-- Disconnect and remove stored connections
	for _, connection in objectConnections[part] do
		connection:Disconnect()
	end
	objectConnections[part] = nil
end

local function setUpObjectSubcontainer1(container: Instance)
	-- Get container connections
	local objectConnections = taggedContainerConnections[container]

	-- Get subcontainer
	local subcontainer = container:WaitForChild(containerName1)

	-- Touched subcontainer
	do
		-- Default connections
		createDefault(objectConnections, subcontainer, {})

		-- Subcontainer children
		local containerChildren = subcontainer:GetChildren()
		task.defer(function()
			for _, child in containerChildren do
				onChildObjectAdded1(container, child)
			end
		end)
		table.insert(objectConnections[subcontainer], subcontainer.ChildAdded:Connect(function(child: Instance)
			onChildObjectAdded1(container, child)
		end))
		table.insert(objectConnections[subcontainer], subcontainer.ChildRemoved:Connect(function(child: Instance)
			cleanUpChildObject1(container, child)
		end))
	end
end

-- For subcontainer 2 (if needed)
-- nothing

-- The container

local function setUpObjectContainer(container: Instance)
	-- Set up connections
	local objectConnections: ObjectConnections = {}
	taggedContainerConnections[container] = objectConnections

	-- Create connections
	setUpObjectSubcontainer1(container)
end

local function cleanUpObjectContainer(container: Instance)
	-- Disconnect and remove stored connections
	if taggedContainerConnections[container] then
		for object, connections in taggedContainerConnections[container] do
			for _, connection in connections do
				connection:Disconnect()
			end
			taggedContainerConnections[container][object] = nil
		end
		taggedContainerConnections[container] = nil
	end
end

local function validateObject(object: Instance)
	return object:IsA("Instance")
end


---------- Module functions ----------

function Module.addInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Validate unique
	if taggedContainerConnections[object] then
		return
	end

	-- Set up object
	setUpObjectContainer(object)
end

function Module.removeInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Clean up object
	cleanUpObjectContainer(object)
end


---------- Return module ----------
return Module

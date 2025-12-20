--!strict

-- Invisible Module


---------- Services ----------

local RunService = game:GetService("RunService")


---------- Imports ----------

local PieMapKit_SharedStorage = script.Parent.Parent.Parent
local _OtherModules = PieMapKit_SharedStorage:WaitForChild("OtherModules")
local UIUtil = require(_OtherModules:WaitForChild("UIUtil"))


---------- Types ----------

type ObjectConnections = {[Instance]: {RBXScriptConnection}}


---------- Globals ----------

local Globals = {}
Globals.taggedContainer_object_connections = {} :: {[Instance]: ObjectConnections}


---------- Local functions ----------

local setUpChildObject
local onChildObjectAdded
local cleanUpChildObject
local setUpObjectContainer
local cleanUpObjectContainer
local validateObject


----- Container functions -----

setUpChildObject = function(container: Instance, object: Instance)
	-- Get container connections
	local objectConnections = Globals.taggedContainer_object_connections[container]

	-- Set up connections
	local connections = {}
	objectConnections[object] = connections

	-- Make object & descendants invisible
	UIUtil.setTransparency(object, 1)
end

onChildObjectAdded = function(container: Instance, child: Instance)
	-- Get container connections
	local objectConnections = Globals.taggedContainer_object_connections[container]

	-- Validate unique
	if objectConnections[child] then
		return
	end

	-- Set up child
	setUpChildObject(container, child)
end

cleanUpChildObject = function(container: Instance, child: Instance)
	-- Get container connections
	local objectConnections = Globals.taggedContainer_object_connections[container]

	-- Disconnect and remove stored connections
	for _, connection in objectConnections[child] do
		connection:Disconnect()
	end
	objectConnections[child] = nil
end

setUpObjectContainer = function(container: Instance)
	-- Validate client
	if not RunService:IsClient() then
		return
	end

	-- Set up connections
	local objectConnections: ObjectConnections = {}
	Globals.taggedContainer_object_connections[container] = objectConnections

	if not objectConnections[container] then
		objectConnections[container] = {}
	end

	-- Set up container
	setUpChildObject(container, container)

	-- Set up container descendants
    do
		local containerChildren = container:GetDescendants()
		task.defer(function()
			for _, child in containerChildren do
				onChildObjectAdded(container, child)
			end
		end)
		table.insert(objectConnections[container], container.DescendantAdded:Connect(function(child: Instance)
			onChildObjectAdded(container, child)
		end))
		table.insert(objectConnections[container], container.DescendantRemoving:Connect(function(child: Instance)
			cleanUpChildObject(container, child)
		end))
	end
end

cleanUpObjectContainer = function(container: Instance)
	-- Disconnect and remove stored connections
	if Globals.taggedContainer_object_connections[container] then
		for object, connections in Globals.taggedContainer_object_connections[container] do
			for _, connection in connections do
				connection:Disconnect()
			end
			Globals.taggedContainer_object_connections[container][object] = nil
		end
		Globals.taggedContainer_object_connections[container] = nil
	end
end

validateObject = function(object: Instance)
	return object:IsA("Instance")
end


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.addInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Validate unique
	if Globals.taggedContainer_object_connections [object] then
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

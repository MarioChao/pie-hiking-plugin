--!strict

-- Invisible Module


---------- Services ----------

local RunService = game:GetService("RunService")


---------- Types ----------

type ObjectConnections = {[Instance]: {RBXScriptConnection}}


---------- Variables ----------

local taggedContainerConnections: {[Instance]: ObjectConnections} = {}


---------- Local functions ----------

----- Container functions -----

local function setUpChildObject(container: Instance, part: BasePart)
	-- Get container connections
	local objectConnections = taggedContainerConnections[container]

	-- Set up connections
	local connections = {}
	objectConnections[part] = connections

	-- Make part invisible
    part.LocalTransparencyModifier = 1
end

local function onChildObjectAdded(container: Instance, child: Instance)
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
	setUpChildObject(container, child)
end

local function cleanUpChildObject(container: Instance, child: Instance)
	-- Get container connections
	local objectConnections = taggedContainerConnections[container]

	-- Disconnect and remove stored connections
	for _, connection in objectConnections[child] do
		connection:Disconnect()
	end
	objectConnections[child] = nil
end

local function setUpObjectContainer(container: Instance)
	-- Validate client
	if not RunService:IsClient() then
		return
	end

	-- Set up connections
	local objectConnections: ObjectConnections = {}
	taggedContainerConnections[container] = objectConnections

	if not objectConnections[container] then
		objectConnections[container] = {}
	end

	-- Set up container
	if container:IsA("BasePart") then
		setUpChildObject(container, container)
	end

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


---------- Module ----------

local Module = {}


----- Module fields -----

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

--!strict
-- Position Teleporters Module


---------- Module ----------
local Module = {}


---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


---------- Types ----------

type ObjectConnections = {[Instance]: {RBXScriptConnection}}


---------- Instances ----------


---------- Variables ----------

local containerName1 = "Teleporters"
local containerName2 = "Destinations"

local taggedContainerConnections: {[Instance]: ObjectConnections} = {}


---------- Helper functions ----------

local function getRandomElement<T>(source: {T}): T
	local index = math.random(1, #source)
	return source[index]
end

local function createDefault<K, V>(table: {[K]: V}, key: K, default: V)
	if not table[key] then
		table[key] = default
	end
end


---------- Local functions ----------
-- Define general functions here

local function onTeleporterActivated(container: Instance, character: Model)
	-- Validate player
	local player = Players:GetPlayerFromCharacter(character)
	if not (character and player) then
		return
	end

	-- Validate humanoid alive
	local humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	if not (humanoid and humanoid.Health > 0) then
		return
	end

	-- Validate humanoid root part
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart?
	if not humanoidRootPart then
		return
	end

	-- Get destination container
	local destinationContainer = container:FindFirstChild(containerName2)
	if not destinationContainer then
		return
	end

	-- Select a destination part
	local destinationParts: {BasePart} = {}
	for _, object in destinationContainer:GetChildren() do
		if object:IsA("BasePart") then
			table.insert(destinationParts, object)
		end
	end
	local destinationPart: BasePart = getRandomElement(destinationParts)

	-- Get destination CFrame
	local destinationCFrame = CFrame.new(destinationPart.CFrame.Position)
	destinationCFrame += Vector3.new(0, destinationPart.Size.Y / 2, 0)
	destinationCFrame *= humanoidRootPart.CFrame.Rotation

	-- Move player to destination
	humanoidRootPart:PivotTo(destinationCFrame)
	-- character:PivotTo(destinationCFrame)
end

-- For subcontainer 1 (teleporters)

local function setUpChildObject1(container: Instance, part: BasePart)
	-- Get container connections
	local objectConnections = taggedContainerConnections[container]

	-- Set up connections
	local connections = {}
	objectConnections[part] = connections

	-- Create connections
	table.insert(connections, part.Touched:Connect(function(otherPart: BasePart)
		onTeleporterActivated(container, otherPart.Parent)
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

	-- Clicked subcontainer
	do
		-- Get click detector
		local clickDetector = subcontainer:FindFirstChildWhichIsA("ClickDetector")

		-- Click detection
		if container:GetAttribute("CanClick") == true then
			if not clickDetector then
				warn(`No click detector found for {subcontainer.Name}!`)
			else
				-- Default connections
				createDefault(objectConnections, clickDetector, {})

				-- Connections
				table.insert(
					objectConnections[clickDetector],
					clickDetector.MouseClick:Connect(function(playerWhoClicked: Player)
						onTeleporterActivated(container, playerWhoClicked.Character)
					end)
				)
			end
		else
			if clickDetector then
				-- Disable
				clickDetector.MaxActivationDistance = 0
			end
		end
	end

	-- Touched subcontainer
	if container:GetAttribute("CanTouch") == true then
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
	-- Validate client
	if not RunService:IsClient() then
		return
	end

	-- Set up connections
	taggedContainerConnections[container] = {}

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

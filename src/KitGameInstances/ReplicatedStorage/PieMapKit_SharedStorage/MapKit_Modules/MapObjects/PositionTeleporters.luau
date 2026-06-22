--!strict
-- Position Teleporters Module


---------- Module ----------
local Module = {}


---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")


---------- Types ----------

type ObjectConnections = {[Instance]: {RBXScriptConnection}}


---------- Instances ----------


---------- Constants ----------

local Constants = {}

Constants.containerName1 = "Teleporters"
Constants.containerName2 = "Destinations"

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.taggedContainerConnections = {} :: {[Instance]: ObjectConnections}
Globals.teleportPlayer_throttled = {} :: {[Player]: boolean}


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

local function transitionPivotToPosition(pivotInstance: PVInstance, targetPosition: Vector3, transitionTime: number)
	local initialPosition = pivotInstance:GetPivot().Position
	local startTime = time()
	local currentTime = 0
	while currentTime < transitionTime do
		-- Move
		local rawAlpha = currentTime / transitionTime
		local tweenedAlpha = TweenService:GetValue(rawAlpha, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local intermediatePosition = initialPosition:Lerp(targetPosition, tweenedAlpha)
		local intermediateCFrame = pivotInstance:GetPivot().Rotation + intermediatePosition
		pivotInstance:PivotTo(intermediateCFrame)

		-- Wait
		RunService.Heartbeat:Wait()
		currentTime = time() - startTime
	end

	-- Move to target
	local targetCFrame = pivotInstance:GetPivot().Rotation + targetPosition
	pivotInstance:PivotTo(targetCFrame)
end


---------- Local functions ----------
-- Define general functions here

local function onTeleporterActivated(container: Instance, character: Model?)
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
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	if not humanoidRootPart then
		return
	end

	-- Get destination container
	local destinationContainer = container:FindFirstChild(Constants.containerName2)
	if not destinationContainer then
		return
	end

	-- Check throttle
	if Globals.teleportPlayer_throttled[player] then
		return
	end
	Globals.teleportPlayer_throttled[player] = true

	do
		-- Select a destination part
		local destinationParts: {BasePart} = {}
		for _, object in destinationContainer:GetChildren() do
			if object:IsA("BasePart") then
				table.insert(destinationParts, object)
			end
		end
		local destinationPart: BasePart = getRandomElement(destinationParts)
	
		-- Get destination position
		local destinationPosition = destinationPart.CFrame.Position
		destinationPosition += Vector3.new(0, destinationPart.Size.Y / 2, 0)
	
		-- Get transition time
		local transitionTime = tonumber(container:GetAttribute("TransitionTime")) or 0
	
		-- Move player to destination
		if transitionTime < 1e-9 then
			-- Instant
			local destinationCFrame = CFrame.new(destinationPosition)
			destinationCFrame *= humanoidRootPart.CFrame.Rotation
			humanoidRootPart:PivotTo(destinationCFrame)
		else
			-- Transition
			humanoidRootPart.Anchored = true
			humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
			transitionPivotToPosition(humanoidRootPart, destinationPosition, transitionTime)
			humanoidRootPart.Anchored = false
		end
	end

	-- Revert throttle
	Globals.teleportPlayer_throttled[player] = nil
end

-- For subcontainer 1 (teleporters)

local function setUpChildObject1(container: Instance, part: BasePart)
	-- Get container connections
	local objectConnections = Globals.taggedContainerConnections[container]

	-- Set up connections
	local connections = {}
	objectConnections[part] = connections

	-- Create connections
	table.insert(connections, part.Touched:Connect(function(otherPart: BasePart)
		onTeleporterActivated(container, otherPart.Parent :: Model)
	end))
end

local function onChildObjectAdded1(container: Instance, child: Instance)
	-- Validate child
	if not child:IsA("BasePart") then
		return
	end

	-- Get container connections
	local objectConnections = Globals.taggedContainerConnections[container]

	-- Validate unique
	if objectConnections[child] then
		return
	end

	-- Set up child
	setUpChildObject1(container, child)
end

local function cleanUpChildObject1(container: Instance, child: Instance)
	-- Get container connections
	local objectConnections = Globals.taggedContainerConnections[container]

	-- Disconnect and remove stored connections
	for _, connection in objectConnections[child] do
		connection:Disconnect()
	end
	objectConnections[child] = nil
end

local function setUpObjectSubcontainer1(container: Instance)
	-- Get container connections
	local objectConnections = Globals.taggedContainerConnections[container]

	-- Get subcontainer
	local subcontainer = container:WaitForChild(Constants.containerName1)

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
	-- Validate environment
	if container:GetAttribute("IsServerSided") == true then
		if not RunService:IsServer() then
			return
		end
	else
		if not RunService:IsClient() then
			return
		end
	end

	-- Set up connections
	Globals.taggedContainerConnections[container] = {}

	-- Create connections
	setUpObjectSubcontainer1(container)
end

local function cleanUpObjectContainer(container: Instance)
	-- Disconnect and remove stored connections
	if Globals.taggedContainerConnections[container] then
		for object, connections in Globals.taggedContainerConnections[container] do
			for _, connection in connections do
				connection:Disconnect()
			end
			Globals.taggedContainerConnections[container][object] = nil
		end
		Globals.taggedContainerConnections[container] = nil
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
	if Globals.taggedContainerConnections[object] then
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

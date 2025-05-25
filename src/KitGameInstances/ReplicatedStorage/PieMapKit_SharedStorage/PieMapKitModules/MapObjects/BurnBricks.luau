--!strict
-- Burn Bricks Module


---------- Module ----------
local Module = {}


---------- Services ----------

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local PieMapKit_SharedStorage = script.Parent.Parent.Parent


---------- Types ----------

type BurnBrickAttributes = {
	BurnColor: Color3,
	BurnSeconds: number,
}


---------- Instances ----------

local PieMapKitEvents = PieMapKit_SharedStorage:WaitForChild("PieMapKitEvents")
local BurnPieRemote = PieMapKitEvents.BurnPieRemote


---------- Variables ----------

local taggedConnections: {[BasePart]: {RBXScriptConnection}} = {}


---------- Helper functions ----------

local function getPieModel(instance: Instance?): Model?
	-- Find a pie model by looking through the parent instances
	local loopCount = 0
	while instance and loopCount < 20 do
		-- Check if instance is a pie model
		if instance:IsA("Model") and instance.Name == "PieModel" and instance:FindFirstChild("MainPart") then
			return instance
		end

		-- Update variables
		local parent: Instance? = instance:FindFirstAncestorWhichIsA("Model")
		instance = parent
		loopCount += 1
	end
	return nil
end


---------- Local functions ----------
-- Define general functions here

local function burnPieAction(pie: Model, burnColor: Color3)
	-- Validate main part
	local mainPart = pie:FindFirstChild("MainPart") or pie:FindFirstChildWhichIsA("BasePart")
	if not mainPart then
		return
	end

	-- Burn
	local fire = Instance.new("Fire")
	fire.Parent = mainPart

	-- Color parts & meshes
	for _, object in pie:GetDescendants() do
		if object:IsA("BasePart") then
			object.Color = burnColor
		elseif object:IsA("DataModelMesh") then
			object.VertexColor = Vector3.new(burnColor.R, burnColor.G, burnColor.B)
		elseif object:IsA("Fire") then
			-- object.Color = burnColor
		end
	end
end

local function destroyPie(pie: Model, delaySeconds: number)
	Debris:AddItem(pie, delaySeconds)
end

local function burnPieServer(pie: Model, brickAttributes: BurnBrickAttributes)
	-- Get burn info
	local burnColor = brickAttributes["BurnColor"] or Color3.new()
	local burnSeconds = brickAttributes["BurnSeconds"] or 1

	-- Validate color
	if typeof(burnColor) == "BrickColor" then
		burnColor = (burnColor :: BrickColor).Color
	end

	-- Burn & destroy pie
	task.defer(function()
		burnPieAction(pie, burnColor)
	end)
	destroyPie(pie, burnSeconds)
end

local function onBurnBrickTouched(brickAttributes: BurnBrickAttributes, otherPart: BasePart)
	-- Validate pie
	local pieModel = getPieModel(otherPart)
	if not pieModel then
		return
	end

	-- Get burn info
	local burnColor = brickAttributes["BurnColor"] or Color3.new()
	local burnSeconds = brickAttributes["BurnSeconds"] or 1

	-- Validate color
	if typeof(burnColor) == "BrickColor" then
		burnColor = (burnColor :: BrickColor).Color
	end

	-- Burn & destroy pie
	task.defer(function()
		burnPieAction(pieModel, burnColor)
	end)
	destroyPie(pieModel, burnSeconds)

	-- Check environment
	if RunService:IsClient() then
		-- Burn pie on server
		BurnPieRemote:FireServer("BurnPie", pieModel, brickAttributes)
	end
end

local function setUpObject(part: BasePart)
	-- Get attributes
	local attributes = {
		BurnColor = part:GetAttribute("BurnColor"),
		BurnSeconds = part:GetAttribute("BurnSeconds"),
	}

	-- Set up connections
	local connections = {}
	taggedConnections[part] = connections

	-- Create connections
	table.insert(connections, part.TouchEnded:Connect(function(otherPart: BasePart)
		onBurnBrickTouched(attributes, otherPart)
	end))
end

local function cleanUpObject(part: BasePart)
	-- Disconnect and remove stored connections
	if taggedConnections[part] then
		for _, connection in taggedConnections[part] do
			connection:Disconnect()
		end
		taggedConnections[part] = nil
	end
end

local function validateObject(object: Instance): boolean
	return object:IsA("BasePart")
end

local function validatePieOwner(pie: Model, player: Player): boolean
	-- Validate parameters
	if not (pie and typeof(pie) == "Instance") then
		return
	end

	-- Validate creator
	local CreatorValue: ObjectValue = pie:FindFirstChild("Creator")
	local Creator = CreatorValue and CreatorValue.Value
	if not Creator then
		return false
	end

	-- Check player match
	return Creator == player
end


---------- Event functions ----------

local function onBurnPieServerEvent(caller: Player, action: string, pie: Model, ...)
	-- Validate player
	if not validatePieOwner(pie, caller) then
		return
	end

	-- Actions
	if action == "BurnPie" then
		burnPieServer(pie, ...)
	end
end


---------- Module functions ----------

function Module.addInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Validate unique
	if taggedConnections[object] then
		return
	end

	-- Set up object
	setUpObject(object)
end

function Module.removeInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Clean up object
	cleanUpObject(object)
end


---------- Calling / connecting functions ----------

if RunService:IsServer() then
	BurnPieRemote.OnServerEvent:Connect(onBurnPieServerEvent)
end


---------- Return module ----------
return Module

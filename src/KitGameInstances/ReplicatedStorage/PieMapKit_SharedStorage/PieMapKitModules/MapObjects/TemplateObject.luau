--!strict
-- Template Object Module
-- For directly tagged parts

---------- Module ----------
local Module = {}

---------- Services ----------

local ReplicatedStorage = script.Parent.Parent.Parent or game:GetService("ReplicatedStorage")

---------- Types ----------

---------- Instances ----------

---------- Variables ----------

local taggedConnections: {[BasePart]: {RBXScriptConnection}} = {}

---------- Helper functions ----------

---------- Local functions ----------
-- Define general functions here

local function setUpObject(part: BasePart)
	-- Set up connections
	local connections = {}
	taggedConnections[part] = connections

	-- Create connections
	table.insert(connections, part.Touched:Connect(function(otherPart: BasePart)
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

local function validateObject(object: Instance)
	return object:IsA("BasePart")
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

---------- Return module ----------
return Module

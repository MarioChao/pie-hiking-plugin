--!strict
-- Button Functions Module


---------- Module ----------
local ButtonFunctions = {}


---------- Services ----------

local ChangeHistoryService = game:GetService("ChangeHistoryService")


---------- Imports ----------

local MapKit = require(script.MapKit)
local PieTool = require(script.PieTool)
local DGAnimation = require(script.DGAnimation)


---------- Variables ----------

local defaultWrapper


---------- Local functions ----------

local function changeHistoryServiceWrap(warnMessage: string, finishOperation: Enum.FinishRecordingOperation)
	return function(name: string, callback: () -> any)
		local recording = ChangeHistoryService:TryBeginRecording(name)
		if not recording then
			warn(warnMessage)
			return
		end

		local success, result = pcall(callback)
		if not success then
			warn("Error in plugin function.")
			warn(result)
		end

		ChangeHistoryService:FinishRecording(recording, finishOperation)
	end
end

local function setUpWrapper()
	defaultWrapper = changeHistoryServiceWrap("Plugin error when starting recording", Enum.FinishRecordingOperation.Commit)
end


---------- Module functions ----------

function ButtonFunctions.setUpPieTool()
	defaultWrapper("Set up pie tool", PieTool.setUp)
end

function ButtonFunctions.insertRegularPieTool()
	defaultWrapper("Insert (bake) regular pie tool", PieTool.insertRegular)
end

function ButtonFunctions.insertBeginnerPieTool()
	defaultWrapper("Insert (bake) beginner pie tool", PieTool.insertBeginner)
end

function ButtonFunctions.setUpMapKit()
	defaultWrapper("Set up map kit", MapKit.setUp)
end

function ButtonFunctions.insertMapKit()
	defaultWrapper("Insert map kit", MapKit.insert)
end

function ButtonFunctions.insertAnimation()
	defaultWrapper("Insert animation", DGAnimation.insert)
end


---------- Calling / connecting functions ----------

setUpWrapper()


---------- Return module ----------
return ButtonFunctions

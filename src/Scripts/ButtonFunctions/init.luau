--!strict

-- Button Functions


---------- Services ----------

local ChangeHistoryService = game:GetService("ChangeHistoryService")


---------- Imports ----------

local MapKit = require(script.MapKit)
local PieTool = require(script.PieTool)
local DGAnimation = require(script.DGAnimation)


---------- Globals ----------

local Globals = {}


---------- Local functions ----------

local changeHistoryServiceWrap


----- Change history -----

changeHistoryServiceWrap = function(warnMessage: string, finishOperation: Enum.FinishRecordingOperation)
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


----- Main -----

local function main()
	Globals.defaultWrapper = changeHistoryServiceWrap("Plugin error when starting recording", Enum.FinishRecordingOperation.Commit)
end


---------- Calling function ----------

main()


---------- Module ----------

local ButtonFunctions = {}


----- Module fields -----

function ButtonFunctions.insertPieModule()
	Globals.defaultWrapper("Insert pie module folder", PieTool.insertModuleFolder)
end

function ButtonFunctions.insertPiePackage()
	Globals.defaultWrapper("Insert pie package", PieTool.insertPackage)
end

function ButtonFunctions.setUpPieTool()
	Globals.defaultWrapper("Set up pie tool container scripts", PieTool.setUpContainerScripts)
end

function ButtonFunctions.insertClassicPieTool()
	Globals.defaultWrapper("Insert (bake) classic pie tool", PieTool.insertClassic)
end

function ButtonFunctions.insertBeginnerPieTool()
	Globals.defaultWrapper("Insert (bake) beginner pie tool", PieTool.insertBeginner)
end

function ButtonFunctions.setUpMapKit()
	Globals.defaultWrapper("Set up map kit", MapKit.setUp)
end

function ButtonFunctions.insertMapKit()
	Globals.defaultWrapper("Insert map kit", MapKit.insert)
end

function ButtonFunctions.insertAnimation()
	Globals.defaultWrapper("Insert animation", DGAnimation.insert)
end


---------- Return module ----------

table.freeze(ButtonFunctions)
return ButtonFunctions

--!strict
-- DG Animation Module


---------- Module ----------
local Module = {}


---------- Services ----------

local Selection = game:GetService("Selection")


---------- Instances ----------

local PluginFolder = script.Parent.Parent.Parent

local AnimationSetup: Folder


---------- Local functions ----------

local function insertAnimationSetup(): {Instance}
	local newAnimationSetup: typeof(AnimationSetup) = AnimationSetup:Clone()
	newAnimationSetup.Parent = workspace

	return {newAnimationSetup}
end

local function refreshAnimationSetup()
	AnimationSetup = game:GetObjects("rbxassetid://17457896802")[1]
	AnimationSetup.Name = `DG Animation Setup (from plugin)`
end


---------- Module functions ----------

function Module.insert()
	refreshAnimationSetup()
	local addedInstances = insertAnimationSetup()
	Selection:Set(addedInstances)
end


---------- Return module ----------
return Module

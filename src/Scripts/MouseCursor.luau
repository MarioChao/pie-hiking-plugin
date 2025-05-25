--!strict
-- Mouse Cursor Module


---------- Module ----------
local MouseCursor = {}


---------- Variables ----------

local plugin: Plugin


---------- Local functions ----------

local function setCursor(cursorAsset: string)
	plugin:GetMouse().Icon = cursorAsset
end


---------- Module functions ----------

function MouseCursor.setPlugin(thePlugin: Plugin)
	plugin = thePlugin
end

function MouseCursor.setCursor(cursorAsset: string)
	setCursor(cursorAsset)
end


---------- Return module ----------
return MouseCursor

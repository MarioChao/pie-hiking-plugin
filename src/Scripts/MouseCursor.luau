--!strict

-- Mouse Cursor Module


---------- Variables ----------

local plugin: Plugin


---------- Local functions ----------

local function setCursor(cursorAsset: string)
	plugin:GetMouse().Icon = cursorAsset
end


---------- Module ----------

local MouseCursor = {}


---------- Module fields ----------

function MouseCursor.setPlugin(thePlugin: Plugin)
	plugin = thePlugin
end

function MouseCursor.setCursor(cursorAsset: string)
	setCursor(cursorAsset)
end


---------- Return module ----------

return MouseCursor

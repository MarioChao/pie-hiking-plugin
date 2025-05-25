--!strict
-- Studio Theme Module


---------- Module ----------
local StudioTheme = {}


---------- Local functions ----------

local function getStudioTheme(): StudioTheme
	return settings().Studio.Theme :: StudioTheme
end

-- Modified from https://create.roblox.com/docs/studio/building-studio-widgets#changing-studio-color-themes
local function syncGuiColors(objects)
	local function setColors()
		local studioTheme = getStudioTheme()
		for _, guiObject in objects do
			-- Sync background color
			guiObject.BackgroundColor3 = studioTheme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
			-- Sync text color
			if (guiObject:IsA("TextBox") or guiObject:IsA("TextButton") or guiObject:IsA("TextLabel")) then
				guiObject.TextColor3 = studioTheme:GetColor(Enum.StudioStyleGuideColor.MainText)
			end
			-- Sync scroll bar color
			if (guiObject:IsA("ScrollingFrame")) then
				guiObject.ScrollBarImageColor3 = studioTheme:GetColor(Enum.StudioStyleGuideColor.MainText)
			end
		end
	end
	-- Run 'setColors()' function to initially sync colors
	setColors()
	-- Connect 'ThemeChanged' event to the 'setColors()' function
	settings().Studio.ThemeChanged:Connect(setColors)
end


---------- Module functions ----------

function StudioTheme.syncGuiColors(objects: {Instance})
	syncGuiColors(objects)
end


---------- Return module ----------
return StudioTheme

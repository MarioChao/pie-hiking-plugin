--!strict
-- Pie Hiking Plugin


---------- Validate environment ----------
-- Validate the script's environment before running any code

local RunService = game:GetService("RunService")

-- For certain plugin scripts
if not RunService:IsEdit() then
	return
end


---------- Imports ----------

local PluginScripts = script.Parent
local ButtonFunctions = require(PluginScripts.ButtonFunctions)
local MouseCursor = require(PluginScripts.MouseCursor)
local StudioTheme = require(PluginScripts.StudioTheme)


---------- Instances ----------

local PluginFolder = script.Parent.Parent

local PieHikingToolbar = plugin:CreateToolbar("Pie Hiking")
local PieHikingToolbarButton: PluginToolbarButton

local PieHikingWidget: DockWidgetPluginGui

local WidgetGuis = PluginFolder.WidgetGuis
local PieHikingWidgetGui = WidgetGuis.PieHiking

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	true,
	300,
	300,
	300,
	200
)


---------- Plugin event functions ----------

local function onPieHikingToolbarButtonClicked()
	PieHikingWidget.Enabled = not PieHikingWidget.Enabled
end

local function onPieHikingWidgetClosed()
	PieHikingToolbarButton:SetActive(true)
	PieHikingToolbarButton:SetActive(false)
	PieHikingWidget.Enabled = false
end


---------- Local functions ----------

local function setUpPluginToolbar()
	PieHikingToolbarButton = PieHikingToolbar:CreateButton(
		"Start Pie Hiking",
		"Set up the pie tool or the map kit.",
		"rbxassetid://17856554137"
	)

	PieHikingToolbarButton.Click:Connect(onPieHikingToolbarButtonClicked)
end

local function setUpPluginWidgets()
	-- Create widget
	PieHikingWidget = plugin:CreateDockWidgetPluginGui("Pie Hiking Widget", widgetInfo)
	PieHikingWidget.Title = "Pie Hiking"
	PieHikingWidget.Name = "PieHikingPluginGui"

	-- Parent widget gui
	PieHikingWidgetGui.Parent = PieHikingWidget

	-- Deactivate toolbar button when closing widget
	PieHikingWidget:BindToClose(onPieHikingWidgetClosed)
end

local function setUpPluginWidgetButtons()
	-- Set-up button events
	local setUpFrame = PieHikingWidgetGui.ScrollingFrame.SetUpFrame
	setUpFrame.PieToolSetUpButton.MouseButton1Click:Connect(ButtonFunctions.setUpPieTool)
	setUpFrame.PieToolInsertButton.MouseButton1Click:Connect(ButtonFunctions.insertPieTool)
	setUpFrame.MapKitSetUpButton.MouseButton1Click:Connect(ButtonFunctions.setUpMapKit)
	setUpFrame.MapKitInsertButton.MouseButton1Click:Connect(ButtonFunctions.insertMapKit)

	-- Animation button events
	local animationFrame = PieHikingWidgetGui.ScrollingFrame.AnimationFrame
	animationFrame.AnimationInsertButton.MouseButton1Click:Connect(ButtonFunctions.insertAnimation)
end

local function setUpPluginWidgetUis()
	-- Sync frame colors
	StudioTheme.syncGuiColors({
		PieHikingWidgetGui.ScrollingFrame,
		PieHikingWidgetGui.ScrollingFrame.SetUpFrame,
		PieHikingWidgetGui.ScrollingFrame.AnimationFrame,
	})

	-- Set up mouse cursors
	MouseCursor.setPlugin(plugin)
	local buttons = {
		PieHikingWidgetGui.ScrollingFrame.SetUpFrame.PieToolSetUpButton,
		PieHikingWidgetGui.ScrollingFrame.SetUpFrame.PieToolInsertButton,
		PieHikingWidgetGui.ScrollingFrame.SetUpFrame.MapKitSetUpButton,
		PieHikingWidgetGui.ScrollingFrame.SetUpFrame.MapKitInsertButton,
		PieHikingWidgetGui.ScrollingFrame.AnimationFrame.AnimationInsertButton,
	}
	for _, object in buttons do
		object.MouseEnter:Connect(function()
			MouseCursor.setCursor("rbxasset://SystemCursors/PointingHand")
		end)
		object.MouseLeave:Connect(function()
			MouseCursor.setCursor("")
		end)
	end
end


---------- Event functions ----------


---------- Set up function ----------
local function initSetUp()
	setUpPluginToolbar()
	setUpPluginWidgets()
	setUpPluginWidgetButtons()
	setUpPluginWidgetUis()
end


---------- Calling / connecting functions ----------

initSetUp()

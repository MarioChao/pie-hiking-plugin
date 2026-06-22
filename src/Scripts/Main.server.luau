--!strict

-- Plugin Main


---------- Validate environment ----------

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


---------- Constants ----------

local Constants = {}

Constants.pluginFolder = script.Parent.Parent

Constants.pieHikingToolbar = plugin:CreateToolbar("Pie Hiking")
Constants.pieHikingToolbarButton = Constants.pieHikingToolbar:CreateButton(
	"Start Pie Hiking",
	"Set up the pie tool or the map kit.",
	"rbxassetid://17856554137"
)

Constants.widgetGuis = Constants.pluginFolder.WidgetGuis
Constants.pieHikingWidgetGui = Constants.widgetGuis.PieHikingPluginGuis

Constants.widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	true,
	300,
	300,
	300,
	200
)

Constants.pieHikingWidget = plugin:CreateDockWidgetPluginGuiAsync("Pie Hiking Widget", Constants.widgetInfo)

table.freeze(Constants)


---------- Local functions ----------

local onPieHikingToolbarButtonClicked
local onPieHikingWidgetClosed

local setUpPluginToolbar
local setUpPluginWidgets
local setUpPluginWidgetButtons
local setUpPluginWidgetUis


----- Plugin events -----

onPieHikingToolbarButtonClicked = function()
	Constants.pieHikingWidget.Enabled = not Constants.pieHikingWidget.Enabled
end

onPieHikingWidgetClosed = function()
	Constants.pieHikingToolbarButton:SetActive(true)
	Constants.pieHikingToolbarButton:SetActive(false)
	Constants.pieHikingWidget.Enabled = false
end


----- Set up plugin -----

setUpPluginToolbar = function()
	Constants.pieHikingToolbarButton.Click:Connect(onPieHikingToolbarButtonClicked)
end

setUpPluginWidgets = function()
	-- Create widget
	Constants.pieHikingWidget.Title = "Pie Hiking"
	Constants.pieHikingWidget.Name = "PieHikingPluginGui"

	-- Parent widget gui
	Constants.pieHikingWidgetGui.Parent = Constants.pieHikingWidget

	-- Deactivate toolbar button when closing widget
	Constants.pieHikingWidget:BindToClose(onPieHikingWidgetClosed)
end

setUpPluginWidgetButtons = function()
	-- Pie button events
	local scrollingFrame = Constants.pieHikingWidgetGui.ScrollingFrame
	local pieFrame = scrollingFrame.PieFrame.Button_Frame
	pieFrame.PieModuleInsertButton.MouseButton1Click:Connect(ButtonFunctions.insertPieModule)
	pieFrame.PieCustomKitInsertButton.MouseButton1Click:Connect(ButtonFunctions.insertPieCustomKit)
	pieFrame.PieToolSetUpButton.MouseButton1Click:Connect(ButtonFunctions.setUpPieTool)
	pieFrame.PieToolClassicInsertButton.MouseButton1Click:Connect(ButtonFunctions.insertClassicPieTool)
	pieFrame.PieToolBeginnerInsertButton.MouseButton1Click:Connect(ButtonFunctions.insertBeginnerPieTool)

	-- Map kit button events
	local mapKitFrame = scrollingFrame.MapKitFrame.Button_Frame
	mapKitFrame.MapKitSetUpButton.MouseButton1Click:Connect(ButtonFunctions.setUpMapKit)
	mapKitFrame.MapKitInsertButton.MouseButton1Click:Connect(ButtonFunctions.insertMapKit)

	-- Animation button events
	local animationFrame = scrollingFrame.AnimationFrame.Button_Frame
	animationFrame.AnimationInsertButton.MouseButton1Click:Connect(ButtonFunctions.insertAnimation)
end

setUpPluginWidgetUis = function()
	-- Sync frame colors
	StudioTheme.syncGuiColors({
		Constants.pieHikingWidgetGui.ScrollingFrame,
	})

	-- Set up mouse cursors
	MouseCursor.setPlugin(plugin)
	local buttons = {
		Constants.pieHikingWidgetGui.ScrollingFrame.PieFrame.Button_Frame.PieModuleInsertButton,
		Constants.pieHikingWidgetGui.ScrollingFrame.PieFrame.Button_Frame.PieCustomKitInsertButton,
		Constants.pieHikingWidgetGui.ScrollingFrame.PieFrame.Button_Frame.PieToolSetUpButton,
		Constants.pieHikingWidgetGui.ScrollingFrame.PieFrame.Button_Frame.PieToolClassicInsertButton,
		Constants.pieHikingWidgetGui.ScrollingFrame.PieFrame.Button_Frame.PieToolBeginnerInsertButton,
		Constants.pieHikingWidgetGui.ScrollingFrame.MapKitFrame.Button_Frame.MapKitSetUpButton,
		Constants.pieHikingWidgetGui.ScrollingFrame.MapKitFrame.Button_Frame.MapKitInsertButton,
		Constants.pieHikingWidgetGui.ScrollingFrame.AnimationFrame.Button_Frame.AnimationInsertButton,
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


----- Main -----

local function main()
	setUpPluginToolbar()
	setUpPluginWidgets()
	setUpPluginWidgetButtons()
	setUpPluginWidgetUis()
end


---------- Calling function ----------

main()

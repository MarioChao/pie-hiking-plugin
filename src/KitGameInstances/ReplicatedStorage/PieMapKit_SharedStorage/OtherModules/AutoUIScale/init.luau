--!strict

-- Auto UI Scale


---------- Globals ----------

local Globals = {}

Globals.screenGui_sizeChangedConnection = {} :: {[Instance]: RBXScriptConnection?}


---------- Local functions ----------

local autoScaleScreenGui


----- Scaling -----

autoScaleScreenGui = function(screenGui: ScreenGui, uiScale: UIScale, unitSize: Vector2, scaleRange: NumberRange)
    -- Get screen size
    local screenGuiSize = screenGui.AbsoluteSize

    -- Get scale factor
    local scaleVector2: Vector2 = screenGuiSize / unitSize
    local scale = math.min(scaleVector2.X, scaleVector2.Y)

    -- Sanitize scale range
    scale = math.clamp(scale, scaleRange.Min, scaleRange.Max)

    -- Set scale
    uiScale.Scale = scale
end


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.setScreenGuiAutoScale(screenGui: ScreenGui, uiScale: UIScale, unitSize: Vector2, scaleRange: NumberRange)
    if Globals.screenGui_sizeChangedConnection[screenGui] then
        (Globals.screenGui_sizeChangedConnection[screenGui] :: RBXScriptConnection):Disconnect()
    end
    Globals.screenGui_sizeChangedConnection[screenGui] = screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        autoScaleScreenGui(screenGui, uiScale, unitSize, scaleRange)
    end)
end


---------- Return module ----------

table.freeze(Module)
return Module

--!strict


---------- Services ----------

local TweenService = game:GetService("TweenService")


---------- Imports ----------

local InstanceProperty = require(script:WaitForChild("InstanceProperty"))


---------- Constants ----------

local Constants = {}

Constants.transparencyPropertyNames = {
    "Transparency",
    "BackgroundTransparency",
    "TextTransparency",
    "TextStrokeTransparency",
    "ImageTransparency",
}
Constants.attributePrefix = "UIUtil_"

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.instance_tween = {} :: {[Instance]: Tween}
Globals.tween_valid = {} :: {[Tween]: boolean}


---------- Local functions ----------

local getAttributeName
local getDescendantsWithContainer
local canTweenProperty
local storeTransparencyValues
local getTargetTransparencyPropertyTable
local isTargetTransparencyDifferent
local getTransparencyTweenObject

local fade
local setTransparency
local resetTransparency


----- Helper functions -----

getAttributeName = function(str: string)
    return Constants.attributePrefix .. str
end

getDescendantsWithContainer = function(container: Instance)
    local result = container:GetDescendants()
    table.insert(result, container)
    return result
end

canTweenProperty = function(object: Instance, property: string)
    local isPropertyANumber = InstanceProperty.getPropertyType(object, property) == "number"
    local isDeprecatedTransparency = (property == "Transparency" and object:IsA("GuiObject"))
    return isPropertyANumber and not isDeprecatedTransparency
end

storeTransparencyValues = function(object: Instance)
    local attributeName
    for _, property in Constants.transparencyPropertyNames do
        if canTweenProperty(object, property) then
            attributeName = getAttributeName(property)
            if not object:GetAttribute(attributeName) then
                object:SetAttribute(attributeName, InstanceProperty.getProperty(object, property))
            end
        end
    end
end

getTargetTransparencyPropertyTable = function(object: Instance, fadeIn: boolean)
    local propertyTable = {}
    local attributeName
    local targetTransparency
    for _, property in Constants.transparencyPropertyNames do
        if canTweenProperty(object, property) then
            targetTransparency = 1
            if fadeIn then
                attributeName = getAttributeName(property)
                targetTransparency = tonumber(object:GetAttribute(attributeName)) or 1
            end
            propertyTable[property] = targetTransparency
        end
    end
    return propertyTable
end

isTargetTransparencyDifferent = function(object: Instance, fadeIn: boolean)
    local propertyTable = getTargetTransparencyPropertyTable(object, fadeIn)
    local result = false
    for property, value in propertyTable do
        if InstanceProperty.getProperty(object, property) ~= value then
            result = true
            break
        end
    end
    return result
end

getTransparencyTweenObject = function(object: Instance, tweenInfo: TweenInfo, fadeIn: boolean): Tween?
    local propertyTable = getTargetTransparencyPropertyTable(object, fadeIn)
    local result
    if next(propertyTable) then
        result = TweenService:Create(object, tweenInfo, propertyTable)
    end
    return result
end


----- Gui transparency functions -----

-- Fade the transparency of all guis in a container
fade = function(container: Instance, tweenInfo: TweenInfo, fadeIn: boolean, waitForTween: boolean)
    local tweenObjects = {} :: {{
        object: Instance,
        tween: Tween,
    }}
    local createdTween
    for _, object in getDescendantsWithContainer(container) do
        -- Clean up previous tween
        if Globals.instance_tween[object] then
            local tween = Globals.instance_tween[object]
            Globals.tween_valid[tween] = nil
            Globals.instance_tween[object] = nil
            tween:Cancel()
            tween:Destroy()
        end

        -- Create tween only if necessary
        storeTransparencyValues(object)
        if isTargetTransparencyDifferent(object, fadeIn) then
            createdTween = getTransparencyTweenObject(object, tweenInfo, fadeIn)
            if createdTween then
                table.insert(tweenObjects, {
                    object = object,
                    tween = createdTween,
                })
                Globals.instance_tween[object] = createdTween
                Globals.tween_valid[createdTween] = true
            end
        end
    end
    for _, tweenObjectInfo in tweenObjects do
        task.defer(function()
            local object = tweenObjectInfo.object
            local tween = tweenObjectInfo.tween

            -- Play tween if valid
            if Globals.tween_valid[tween] then
                tween:Play()
                Globals.tween_valid[tween] = nil

                -- Clean up dictionary
                tween.Completed:Once(function()
                    if Globals.instance_tween[object] == tween then
                        Globals.instance_tween[object] = nil
                    end
                end)
            end
        end)
    end
    if waitForTween and next(tweenObjects) ~= nil then
        tweenObjects[1].tween.Completed:Wait()
    end
end

-- Set the transparency of all guis in a container
setTransparency = function(container: Instance, transparency: number)
    for _, object in getDescendantsWithContainer(container) do
        storeTransparencyValues(object)
        for _, property in Constants.transparencyPropertyNames do
            if canTweenProperty(object, property) then
                InstanceProperty.setProperty(object, property, transparency)
            end
        end
    end
end

-- Reset the transparency of all guis in a container
resetTransparency = function(container: Instance)
    local targetTransparency
    for _, object in getDescendantsWithContainer(container) do
        storeTransparencyValues(object)
        for _, property in Constants.transparencyPropertyNames do
            if canTweenProperty(object, property) then
                targetTransparency = object:GetAttribute(getAttributeName(property))
                InstanceProperty.setProperty(object, property, targetTransparency)
            end
        end
    end
end


---------- Module ----------

local module = {}


----- Module fields -----

module.fade = fade
module.setTransparency = setTransparency
module.resetTransparency = resetTransparency


---------- Return module ----------

table.freeze(module)
return module

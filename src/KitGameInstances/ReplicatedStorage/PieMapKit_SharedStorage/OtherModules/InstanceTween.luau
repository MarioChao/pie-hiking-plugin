--!strict

-- Instance Tween


---------- Services ----------

local ReflectionService = game:GetService("ReflectionService")
local TweenService = game:GetService("TweenService")


---------- Constants ----------

local Constants = {}

Constants._canTweenTypes = {
    "number",
    "boolean",
    "CFrame",
    "Rect",
    "Color3",
    "UDim",
    "UDim2",
    "Vector2",
    "Vector2int16",
    "Vector3",
}
table.freeze(Constants._canTweenTypes)

Constants._ignoredProperties = {
    "Archivable",
    "Name",
    "Parent",
}
table.freeze(Constants._ignoredProperties)


----- Array to dictionary -----

local function _arrayToSet(array: {any})
    local result = {}
    for _, value in array do
        result[value] = true
    end
    return result
end

Constants.typeof_canTween = _arrayToSet(Constants._canTweenTypes)
table.freeze(Constants.typeof_canTween)

Constants.property_willIgnore = _arrayToSet(Constants._ignoredProperties)
table.freeze(Constants.property_willIgnore)

table.freeze(Constants)


---------- Local functions ----------

local canTweenValue
local tweenOrSetProperties
local getFilledPropertyTable
local getWritablePropertyTableFromInstance


----- Tween / set properties -----

canTweenValue = function(value: any)
	return Constants.typeof_canTween[typeof(value)] == true
end

tweenOrSetProperties = function(
    instance: Instance, rawPropertyTable: {[string]: any}, defaultProperties: {[string]: any}?, ignoredProperties: {string},
    tweenInfo: TweenInfo, waitForTween: boolean
)
    local categorizedPropertyTable = {
		tweened = {} :: {[string]: any},
		set = {} :: {[string]: any},
	}
    local filledPropertyTable
    local tween

    -- Categorize property table
    filledPropertyTable = getFilledPropertyTable(instance, rawPropertyTable, defaultProperties, ignoredProperties)
	for property: string, value: any in filledPropertyTable do
		if canTweenValue(value) then
			categorizedPropertyTable.tweened[property] = value
		else
			categorizedPropertyTable.set[property] = value
		end
	end

    -- Create tween
    local success, errorMessage = pcall(function()
        tween = TweenService:Create(instance, tweenInfo, categorizedPropertyTable.tweened)
    end)
    if not success then
        warn(`[Instance Tween]: Failed to create tween of class {instance.ClassName}, error:`, errorMessage)
    end

    -- Tween & set properties
    task.defer(function()
        for property, value in categorizedPropertyTable.set do
            (instance :: any)[property] = value
        end
    end)
    tween:Play()
    if waitForTween then
        tween.Completed:Wait()
    end
end


----- Get properties -----

getFilledPropertyTable = function(
    instance: Instance, propertyTable: {[string]: any}, defaultProperties: {[string]: any}?, ignoredProperties: {string}
): {[string]: any}
    local property_willIgnore = _arrayToSet(ignoredProperties)
    local className = instance.ClassName
	local classInfo = ReflectionService:GetClass(className)
	local result = {}
	if classInfo.Permits and classInfo.Permits.New then
		-- Fill property from a newly created instance
		local defaultInstance = Instance.new(className)
		local properties = ReflectionService:GetPropertiesOfClass(className)
		for _, property in properties do
			if property.Permits and property.Permits.Write then
				local propertyName = property.Name
                local willIgnore = Constants.property_willIgnore[propertyName] or property_willIgnore[propertyName]
                if not willIgnore then
                    -- Use value from property table if exists
                    if propertyTable[propertyName] ~= nil then
                        result[propertyName] = propertyTable[propertyName]
                    else
                        local success, errorMessage = pcall(function()
                            result[propertyName] = (defaultInstance :: any)[propertyName]
                        end)
                        if not success then
                            warn(`[Instance Tween]: Failed to get property {propertyName} of {className}, error:`, errorMessage)
                        end
                    end
                end
			end
		end
	else
        if defaultProperties then
            for propertyName, value in defaultProperties do
                local willIgnore = Constants.property_willIgnore[propertyName] or property_willIgnore[propertyName]
                if not willIgnore then
                    -- Use value from property table if exists
                    if propertyTable[propertyName] ~= nil then
                        result[propertyName] = propertyTable[propertyName]
                    else
                        result[propertyName] = value
                    end
                end
            end
        end
	end
	return result
end


getWritablePropertyTableFromInstance = function(instance: Instance)
    local className = instance.ClassName
    local properties = ReflectionService:GetPropertiesOfClass(className)
    local result = {}
    for _, property in properties do
        if property.Permits and property.Permits.Write then
            local propertyName = property.Name
            local success, errorMessage = pcall(function()
                result[propertyName] = (instance :: any)[propertyName]
            end)
            if not success then
                warn(`[Instance Tween]: Failed to get property {propertyName} of {className}, error:`, errorMessage)
            end
        end
    end
    return result
end


---------- Module ----------

local Module = {}


----- Module fields -----

Module.canTweenValue = canTweenValue
Module.tweenOrSetProperties = tweenOrSetProperties
Module.getWritablePropertyTableFromInstance = getWritablePropertyTableFromInstance


---------- Return module ----------

table.freeze(Module)
return Module

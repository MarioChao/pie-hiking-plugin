--!strict


---------- Globals ----------

local Globals = {}
Globals.className_hasProperty = {} :: {[string]: {[string]: boolean?}}


---------- Property functions ----------

local hasProperty
local getPropertyType
local getProperty
local setProperty

hasProperty = function(instance: Instance, property: string)
    local className = instance.ClassName
    local pcallSuccess, _
    local result

    -- Initialize hashed result
    if not Globals.className_hasProperty[className] then
        Globals.className_hasProperty[className] = {}
    end

    -- Check hashed result or use pcall
    if Globals.className_hasProperty[className][property] ~= nil then
        result = Globals.className_hasProperty[className][property]
    else
        pcallSuccess, _ = pcall(function()
            instance:IsPropertyModified(property)
        end)
        result = pcallSuccess or false
        Globals.className_hasProperty[className][property] = result
    end
    return result
end

getPropertyType = function(instance: Instance, property: string): any
    return hasProperty(instance, property) and type(instance[property])
end

getProperty = function(instance: Instance, property: string): any
    return hasProperty(instance, property) and instance[property]
end

setProperty = function(instance: Instance, property: string, value: any)
    if hasProperty(instance, property) then
        instance[property] = value
    end
end


---------- Module ----------

local module = {}


----- Module fields -----

module.hasProperty = hasProperty
module.getPropertyType = getPropertyType
module.getProperty = getProperty
module.setProperty = setProperty


---------- Return module ----------

table.freeze(module)
return module

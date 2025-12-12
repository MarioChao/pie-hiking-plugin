--!strict

-- Main Client


---------- Imports ----------

local LightingTypes = require(script.Parent:WaitForChild("Types"))
local UpdateLighting = require(script.Parent:WaitForChild("UpdateLighting"))


---------- Constants ----------

local Constants = {}
Constants.lightingRemoteEvent = script.Parent:WaitForChild("LightingRemoteEvent")
Constants.remoteEventStrings = {
    server = {
        playerConnected = "Player Connected",
    },
    client = {
        updateLighting = "Update Lighting",
    },
}

table.freeze(Constants)


---------- Local functions ----------

local onUpdateLighting


----- Lighting -----

onUpdateLighting = function(lightingConfig: LightingTypes.LightingConfigType)
    UpdateLighting.applyLightingConfig(lightingConfig, nil)
end


----- Main -----

local function main()
    Constants.lightingRemoteEvent.OnClientEvent:Connect(function(mode: string, ...)
        if mode == Constants.remoteEventStrings.client.updateLighting then
            onUpdateLighting(...)
        end
    end)
    Constants.lightingRemoteEvent:FireServer(Constants.remoteEventStrings.server.playerConnected)
end


---------- Calling function ----------

main()

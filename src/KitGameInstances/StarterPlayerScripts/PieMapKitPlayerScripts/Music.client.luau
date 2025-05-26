--!strict
-- Load Lighting Script


---------- Validate container ----------
-- Validate the script's container before running any code

-- For certain client scripts
if not script:FindFirstAncestorWhichIsA("PlayerScripts") then
	return
end


---------- Services----------

local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")
local SoundService = script.Parent.Parent.Parent:FindFirstChild("SoundService") or game:GetService("SoundService")

local PieMapKit_SharedStorage = ReplicatedStorage:WaitForChild("PieMapKit_SharedStorage")
local PieMapKit_Audio = SoundService:WaitForChild("PieMapKit_Audio")


---------- Imports ----------


---------- Types ----------

type AudioInfo = {
	Asset: number,
	PlaybackSpeed: number,
	Volume: number
}


---------- Instances ----------

local PieMapKitEvents = PieMapKit_SharedStorage.PieMapKitEvents
local MusicBindable = PieMapKitEvents.MusicBindable

local AudioPlayer = PieMapKit_Audio.AudioPlayer


---------- Variables ----------

local defaultAudio: AudioInfo = {
	Asset = 9045766377,
	PlaybackSpeed = 0.8,
	Volume = 0.5
}


---------- Local functions ----------

local function setPlayedAudio(audioInfo: AudioInfo)
	AudioPlayer.Asset = `rbxassetid://{audioInfo.Asset}`
	AudioPlayer.PlaybackSpeed = audioInfo.PlaybackSpeed
	AudioPlayer.Volume = audioInfo.Volume
end


---------- Event functions ----------

local function onMusicBindableEvent(action: string, ...)
	if action == "SetAudio" then
		setPlayedAudio(...)
	end
end


---------- Set up function ----------

local function initSetUp()
	setPlayedAudio(defaultAudio)
	AudioPlayer:Play()
end


---------- Calling / connecting functions ----------

MusicBindable.Event:Connect(onMusicBindableEvent)
initSetUp()

--!strict

-- Music


---------- Validate container ----------

-- Replicated storage
if not script:FindFirstAncestorWhichIsA("ReplicatedStorage") then
	return
end


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


---------- Types ----------

type AudioInfo = {
	AssetId: number | string,
	LoopRegion: NumberRange,
	PlaybackRegion: NumberRange,
	PlaybackSpeed: number,
	Volume: number,
}

local AudioPlayingState: {[string]: AudioPlayingState} = {
	FadeOut = "FadeOut",
	FadeIn = "FadeIn",
	Playing = "Playing",
}
type AudioPlayingState = "FadeOut" | "FadeIn" | "Playing"


---------- Constants ----------

local Constants = {}

local PieMapKit_SharedStorage = ReplicatedStorage:WaitForChild("PieMapKit_SharedStorage")

do
	local MapKit_Audio = PieMapKit_SharedStorage:WaitForChild("MapKit_Audio")
	Constants.audioPlayer = MapKit_Audio:WaitForChild("AudioPlayer")
end

do
	local MapKit_Events = PieMapKit_SharedStorage:WaitForChild("MapKit_Events")
	Constants.musicBindable = MapKit_Events:WaitForChild("MusicBindable")
end


table.freeze(Constants)


---------- Variables ----------

local timeFunction = time

local defaultAudio: AudioInfo = (function()
	local customSound = PieMapKit_SharedStorage:FindFirstChild("Custom_DefaultMusicSound") :: Instance
	local result: AudioInfo
	if customSound and customSound:IsA("Sound") then
		result = {
			AssetId = customSound.SoundId,
			LoopRegion = customSound.PlaybackRegionsEnabled and customSound.LoopRegion or NumberRange.new(0),
			PlaybackRegion = customSound.PlaybackRegionsEnabled and customSound.PlaybackRegion or NumberRange.new(0),
			PlaybackSpeed = customSound.PlaybackSpeed,
			Volume = customSound.Volume,
		}
	else
		result = {
			AssetId = 9045766377,
			LoopRegion = NumberRange.new(3.8, 72),
			PlaybackRegion = NumberRange.new(0),
			PlaybackSpeed = 0.8,
			Volume = 0.5,
		}
	end
	return result
end)()

local fadeTime = 1

local targetAudio: AudioInfo = nil

local audioState = AudioPlayingState.Playing
local audioFadeStartTime = timeFunction()
local audioFadeVolumeEndpoints = NumberSequence.new(0, 0)

local playbackTweenInfo = TweenInfo.new(1)


---------- Local functions ----------

local lerp
local rangeMap

local isSameAudio
local setPlayedAudio
local setTargetAudio
local musicLoopFrame

local onMusicBindableEvent


----- Helper -----

lerp = function(value1: number, value2: number, alpha: number)
	return value1 + (value2 - value1) * alpha
end

rangeMap = function(value: number, in1: number, in2: number, out1: number, out2: number, clampToOut: boolean?)
	local alpha = (value - in1) / (in2 - in1)
	local result = lerp(out1, out2, alpha)
	if clampToOut then
		result = math.clamp(result, math.min(out1, out2), math.max(out1, out2))
	end
	return result
end


----- Music -----

isSameAudio = function(audio1: AudioInfo, audio2: AudioInfo)
	if not audio1 or not audio2 then
		return false
	end

	for key, value in audio1 do
		if audio2[key] ~= value then
			return false
		end
	end
	return true
end

setPlayedAudio = function(audioInfo: AudioInfo)
	-- Get audio asset string
	local audioAsset
	if tonumber(audioInfo.AssetId) then
		audioAsset = `rbxassetid://{audioInfo.AssetId}`
	else
		audioAsset = tostring(audioInfo.AssetId)
	end

	-- Check if different audio asset
	local audioPlayer = Constants.audioPlayer
	if audioPlayer.Asset ~= audioAsset then
		-- Set new audio
		audioPlayer.Asset = audioAsset
		audioPlayer.TimePosition = 0
		audioPlayer:Play()

		-- Set playback
		audioPlayer.PlaybackSpeed = audioInfo.PlaybackSpeed

		-- Set playback & loop region
		audioPlayer.LoopRegion = audioInfo.LoopRegion or NumberRange.new(0)
		audioPlayer.PlaybackRegion = audioInfo.PlaybackRegion or NumberRange.new(0)
	else
		-- Set playback (maybe tween?)
		audioPlayer.PlaybackSpeed = audioInfo.PlaybackSpeed

		-- Set playback & loop region
		audioPlayer.LoopRegion = audioInfo.LoopRegion or NumberRange.new(0)
		audioPlayer.PlaybackRegion = audioInfo.PlaybackRegion or NumberRange.new(0)
	end

	-- Fade in audio volume
	audioState = AudioPlayingState.FadeIn
	audioFadeStartTime = timeFunction()
	audioFadeVolumeEndpoints = NumberSequence.new(audioPlayer.Volume, audioInfo.Volume)
end

setTargetAudio = function(audioInfo: AudioInfo)
	-- If same audio, skip
	if isSameAudio(targetAudio, audioInfo) then
		return
	end

	-- Set target audio
	targetAudio = audioInfo

	-- If same asset, play directly (with fade in)
	local audioAsset
	if tonumber(audioInfo.AssetId) then
		audioAsset = `rbxassetid://{audioInfo.AssetId}`
	else
		audioAsset = tostring(audioInfo.AssetId)
	end
	if Constants.audioPlayer.Asset == audioAsset then
		setPlayedAudio(targetAudio)
		return
	end

	-- Fade out old audio
	audioState = AudioPlayingState.FadeOut
	audioFadeStartTime = timeFunction()
	audioFadeVolumeEndpoints = NumberSequence.new(Constants.audioPlayer.Volume, 0)
end

musicLoopFrame = function()
	-- Get current time
	local currentTime = timeFunction()

	-- Set volume function
	local function setAudioVolume()
		-- Lerp volume based on time
		local volumeKeypoints = audioFadeVolumeEndpoints.Keypoints
		Constants.audioPlayer.Volume = rangeMap(
			currentTime - audioFadeStartTime,
			0, fadeTime,
			volumeKeypoints[1].Value, volumeKeypoints[2].Value,
			true
		)
	end

	-- Different states
	if audioState == AudioPlayingState.FadeOut then
		-- Check if fade out finished
		if currentTime > audioFadeStartTime + fadeTime then
			-- Set played audio (switches to "fade in" state)
			setPlayedAudio(targetAudio)
		else
			-- Set volume
			setAudioVolume()
		end
	elseif audioState == AudioPlayingState.FadeIn then
		-- Check if fade in finished
		if currentTime > audioFadeStartTime + fadeTime then
			-- Set playing volume
			Constants.audioPlayer.Volume = audioFadeVolumeEndpoints.Keypoints[2].Value

			-- Switch to "playing" state
			audioState = AudioPlayingState.Playing
		else
			-- Set volume
			setAudioVolume()
		end
	elseif audioState == AudioPlayingState.Playing then
		-- Do nothing
	end
end


----- Event functions -----

onMusicBindableEvent = function(action: string, ...)
	if action == "SetAudio" then
		setTargetAudio(...)
	elseif action == "PlayDefaultAudio" then
		setTargetAudio(defaultAudio)
	end
end


----- Main -----

local function main()
	-- Music event
	Constants.musicBindable.Event:Connect(onMusicBindableEvent)

	-- Music playing loop
	RunService.Heartbeat:Connect(musicLoopFrame)

	-- Set default audio
	setTargetAudio(defaultAudio)
end


---------- Calling function ----------

main()

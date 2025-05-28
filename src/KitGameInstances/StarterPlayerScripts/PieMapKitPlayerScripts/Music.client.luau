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
local RunService = game:GetService("RunService")
local SoundService = script.Parent.Parent.Parent:FindFirstChild("SoundService") or game:GetService("SoundService")

local PieMapKit_SharedStorage = ReplicatedStorage:WaitForChild("PieMapKit_SharedStorage")
local PieMapKit_Audio = SoundService:WaitForChild("PieMapKit_Audio")


---------- Imports ----------


---------- Types ----------

type AudioInfo = {
	AssetId: number,
	PlaybackSpeed: number,
	Volume: number,
}

local AudioPlayingState: {[string]: AudioPlayingState} = {
	FadeOut = "FadeOut",
	FadeIn = "FadeIn",
	Playing = "Playing",
}
type AudioPlayingState = "FadeOut" | "FadeIn" | "Playing"


---------- Instances ----------

local PieMapKitEvents = PieMapKit_SharedStorage.PieMapKitEvents
local MusicBindable = PieMapKitEvents.MusicBindable

local AudioPlayer = PieMapKit_Audio.AudioPlayer


---------- Variables ----------

local timeFunction = time

local defaultAudio: AudioInfo = {
	AssetId = 9045766377,
	PlaybackSpeed = 0.8,
	Volume = 0.5,
}

local fadeTime = 1

local targetAudio: AudioInfo = nil

local audioState = AudioPlayingState.Playing
local audioFadeStartTime = timeFunction()
local audioFadeVolumeEndpoints = NumberSequence.new(0, 0)

local playbackTweenInfo = TweenInfo.new(1)


---------- Helper functions ----------

local function lerp(value1: number, value2: number, alpha: number)
	return value1 + (value2 - value1) * alpha
end

local function rangeMap(value: number, in1: number, in2: number, out1: number, out2: number, clampToOut: boolean?)
	local alpha = (value - in1) / (in2 - in1)
	local result = lerp(out1, out2, alpha)
	if clampToOut then
		result = math.clamp(result, math.min(out1, out2), math.max(out1, out2))
	end
	return result
end

local function isSameAudio(audio1: AudioInfo, audio2: AudioInfo)
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


---------- Local functions ----------

local function setPlayedAudio(audioInfo: AudioInfo)
	-- Get audio asset string
	local audioAsset = `rbxassetid://{audioInfo.AssetId}`

	-- Check if different audio asset
	if AudioPlayer.Asset ~= audioAsset then
		-- Set new audio
		AudioPlayer.Asset = audioAsset
		AudioPlayer.TimePosition = 0
		AudioPlayer:Play()

		-- Set playback
		AudioPlayer.PlaybackSpeed = audioInfo.PlaybackSpeed
	else
		-- Set playback (maybe tween?)
		AudioPlayer.PlaybackSpeed = audioInfo.PlaybackSpeed
	end

	-- Fade in audio volume
	audioState = AudioPlayingState.FadeIn
	audioFadeStartTime = timeFunction()
	audioFadeVolumeEndpoints = NumberSequence.new(AudioPlayer.Volume, audioInfo.Volume)
end

local function setTargetAudio(audioInfo: AudioInfo)
	-- If same audio, skip
	if isSameAudio(targetAudio, audioInfo) then
		return
	end

	-- Set target audio
	targetAudio = audioInfo

	-- If same asset, play directly (with fade in)
	local audioAsset = `rbxassetid://{audioInfo.AssetId}`
	if AudioPlayer.Asset == audioAsset then
		setPlayedAudio(targetAudio)
		return
	end

	-- Fade out old audio
	audioState = AudioPlayingState.FadeOut
	audioFadeStartTime = timeFunction()
	audioFadeVolumeEndpoints = NumberSequence.new(AudioPlayer.Volume, 0)
end

local function musicLoopFrame()
	-- Get current time
	local currentTime = timeFunction()

	-- Set volume function
	local function setAudioVolume()
		-- Lerp volume based on time
		local volumeKeypoints = audioFadeVolumeEndpoints.Keypoints
		AudioPlayer.Volume = rangeMap(
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
			AudioPlayer.Volume = audioFadeVolumeEndpoints.Keypoints[2].Value

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


---------- Event functions ----------

local function onMusicBindableEvent(action: string, ...)
	if action == "SetAudio" then
		setTargetAudio(...)
	elseif action == "PlayDefaultAudio" then
		setTargetAudio(defaultAudio)
	end
end


---------- Set up function ----------

local function initSetUp()
	setTargetAudio(defaultAudio)
end


---------- Calling / connecting functions ----------

MusicBindable.Event:Connect(onMusicBindableEvent)
RunService.Heartbeat:Connect(musicLoopFrame)
initSetUp()

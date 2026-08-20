--!strict

-- Music


---------- Validate container ----------

-- Replicated storage
if not script:FindFirstAncestorWhichIsA("ReplicatedStorage") then
	return
end


---------- Services ----------

local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if not RunService:IsClient() then
	warn('[Music]: Module should only be required from the client!')
end


---------- Imports ----------

local PieMapKit_SharedStorage = ReplicatedStorage:WaitForChild("PieMapKit_SharedStorage")

local _OtherModules = PieMapKit_SharedStorage:WaitForChild("OtherModules")
local AutoUIScale = require(_OtherModules:WaitForChild("AutoUIScale"))
local PresetStarterGui = require(_OtherModules:WaitForChild("PresetStarterGui"))


---------- Types ----------

type AudioInfo = {
	AssetId: number | string,
	LoopRegion: NumberRange,
	PlaybackRegion: NumberRange,
	PlaybackSpeed: number,
	Volume: number,
}

type AudioMetadataInfo = {
	title: string,
	artist: string,
}

local AudioPlayingState: {[string]: AudioPlayingState} = {
	FadeOut = "FadeOut",
	FadeIn = "FadeIn",
	Playing = "Playing",
}
type AudioPlayingState = "FadeOut" | "FadeIn" | "Playing"


---------- Constants ----------

local Constants = {}

Constants.player = Players.LocalPlayer
Constants.playerGui = Constants.player.PlayerGui

do
	local MapKit_Audio = PieMapKit_SharedStorage:WaitForChild("MapKit_Audio")
	Constants.audioDeviceOutput = MapKit_Audio:WaitForChild("AudioDeviceOutput")
	Constants.audioPlayer = MapKit_Audio:WaitForChild("AudioPlayer")
	Constants.audioWire = MapKit_Audio:WaitForChild("Wire")
end

do
	local MapKit_Events = PieMapKit_SharedStorage:WaitForChild("MapKit_Events")
	Constants.musicBindable = MapKit_Events:WaitForChild("MusicBindable")
end

do
	local default_screenGui = script:WaitForChild("DefaultMapKitMusic_ScreenGui")
	local uis = {}
	uis.music_screenGui = PresetStarterGui.getPresetScreenGui("MapKitMusic_ScreenGui", default_screenGui) :: typeof(default_screenGui)
	uis.screenGui_uiScale = uis.music_screenGui:WaitForChild("UIScale")
	uis.creditsLabel_canvasGroup = uis.music_screenGui:WaitForChild("CreditsLabel_CanvasGroup")
	uis.creditsLabelDarken_uiGradent = uis.creditsLabel_canvasGroup:WaitForChild("Darken_UIGradient")

	uis.credits_canvasGroup = uis.creditsLabel_canvasGroup:WaitForChild("Credits_CanvasGroup")
	uis.credits_frame = uis.credits_canvasGroup:WaitForChild("Credits_Frame")
	uis.valueArtist_textLabel = uis.credits_frame:WaitForChild("ValueArtist_TextLabel")
	uis.valueTitle_textLabel = uis.credits_frame:WaitForChild("ValueTitle_TextLabel")

	uis.iconState_canvasGroup = uis.creditsLabel_canvasGroup:WaitForChild("IconState_CanvasGroup")
	uis.icon_frame = uis.iconState_canvasGroup:WaitForChild("Icon_Frame")
	uis.icon_imageButton = uis.icon_frame:WaitForChild("Icon_ImageButton")
	uis.musicState_frame = uis.iconState_canvasGroup:WaitForChild("MusicState_Frame")
	uis.musicState_textLabel = uis.musicState_frame:WaitForChild("MusicState_TextLabel")

	uis.music_screenGui.Parent = Constants.playerGui
	uis.music_screenGui.Enabled = true
	uis.creditsLabelDarken_uiGradent.Enabled = false
	uis.valueArtist_textLabel.Text = "..."
	uis.valueTitle_textLabel.Text = "..."
	uis.musicState_textLabel.Text = "..."

	Constants.music_uis = uis
	table.freeze(uis)
end

Constants.timeFunction = time

Constants.defaultAudio = (function()
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

Constants.fadeTime = 1

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.targetAudio = nil :: AudioInfo?

Globals.audioState = AudioPlayingState.Playing
Globals.audioFadeStartTime = Constants.timeFunction()
Globals.audioFadeVolumeRange = {0, 0}

Globals.assetId_cachedAudioMetadata = {} :: {[number]: AudioMetadataInfo?}
Globals.setMetadataThread = nil :: thread?

Globals.isAudioMuted = false


---------- Local functions ----------

local lerp
local rangeMap

local getAudioAssetMetadata
local getAudioAssetString

local isSameAudio
local setPlayedAudio
local setTargetAudio
local musicLoopFrame

local setUpAudioWire
local toggleMute
local setIsMuted

local onMusicBindableEvent

local setScreenGuiAutoScale


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


----- Asset -----

getAudioAssetMetadata = function(assetId: number): AudioMetadataInfo
	-- Check cached
	if Globals.assetId_cachedAudioMetadata[assetId] then
		return Globals.assetId_cachedAudioMetadata[assetId] :: AudioMetadataInfo
	end

	-- Fetch metadata
	local result = {} :: AudioMetadataInfo
	local success = pcall(function()
		local assetInfo = AssetService:GetAudioMetadataAsync({assetId})[1]
		result.title = assetInfo.Title
		result.artist = assetInfo.Artist
	end)
	if not success then
		result.title = "error"
		result.artist = ""
	end

	-- Cache result if success
	if success then
		Globals.assetId_cachedAudioMetadata[assetId] = result
	end

	-- Return result
	return result
end

getAudioAssetString = function(assetId: number | string)
	local result
	if tonumber(assetId) then
		result = `rbxassetid://{assetId}`
	else
		result = tostring(assetId)
	end
	return result
end


----- Music -----

isSameAudio = function(audio1: AudioInfo?, audio2: AudioInfo?)
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

setPlayedAudio = function(_audioInfo: AudioInfo?)
	-- Sanitize audio info
	local audioInfo = _audioInfo or Constants.defaultAudio

	-- Get audio asset string
	local audioAsset = getAudioAssetString(audioInfo.AssetId)

	-- Check if different audio asset
	local audioPlayer = Constants.audioPlayer
	if audioPlayer.Asset ~= audioAsset then
		--[[ Different audio ]]

		-- Set new audio
		audioPlayer.Asset = audioAsset
		audioPlayer.TimePosition = 0
		audioPlayer:Play()

		-- Set playback
		audioPlayer.PlaybackSpeed = audioInfo.PlaybackSpeed

		-- Set playback & loop region
		audioPlayer.LoopRegion = audioInfo.LoopRegion or NumberRange.new(0)
		audioPlayer.PlaybackRegion = audioInfo.PlaybackRegion or NumberRange.new(0)

		-- Set metadata
		if Globals.setMetadataThread then
			task.cancel(Globals.setMetadataThread)
		end
		Constants.music_uis.valueArtist_textLabel.Text = "..."
		Constants.music_uis.valueTitle_textLabel.Text = "..."
		Globals.setMetadataThread = task.defer(function()
			-- Get metadata
			local assetId = tonumber(string.match(audioAsset, "%d+"))
			local metadata = getAudioAssetMetadata(assetId or 0)
	
			-- Set gui texts
			Constants.music_uis.valueArtist_textLabel.Text = metadata.artist
			Constants.music_uis.valueTitle_textLabel.Text = metadata.title
		end)
	else
		--[[ Same audio ]]

		-- Set playback
		audioPlayer.PlaybackSpeed = audioInfo.PlaybackSpeed

		-- Set playback & loop region
		audioPlayer.LoopRegion = audioInfo.LoopRegion or NumberRange.new(0)
		audioPlayer.PlaybackRegion = audioInfo.PlaybackRegion or NumberRange.new(0)
	end

	-- Fade in audio volume
	Globals.audioState = AudioPlayingState.FadeIn
	Globals.audioFadeStartTime = Constants.timeFunction()
	Globals.audioFadeVolumeRange = {audioPlayer.Volume, audioInfo.Volume}
end

setTargetAudio = function(audioInfo: AudioInfo)
	-- If same audio, skip
	if isSameAudio(Globals.targetAudio, audioInfo) then
		return
	end

	-- Set target audio
	local previousTargetAudio = Globals.targetAudio
	Globals.targetAudio = audioInfo

	-- If same asset as playing, play directly
	local audioAsset = getAudioAssetString(audioInfo.AssetId)
	if Constants.audioPlayer.Asset == audioAsset then
		setPlayedAudio(Globals.targetAudio)
		return
	end

	-- If same asset as target, do nothing
	local previousAudioAsset = previousTargetAudio and getAudioAssetString(previousTargetAudio.AssetId)
	if previousAudioAsset == audioAsset then
		return
	end

	-- Prefetch metadata
	task.defer(function()
		local assetId = tonumber(string.match(audioAsset, "%d+"))
		if assetId and not Globals.assetId_cachedAudioMetadata[assetId] then
			getAudioAssetMetadata(assetId)
		end
	end)

	-- Fade out old audio
	Globals.audioState = AudioPlayingState.FadeOut
	Globals.audioFadeStartTime = Constants.timeFunction()
	Globals.audioFadeVolumeRange = {Constants.audioPlayer.Volume, 0}
end

musicLoopFrame = function()
	-- Get current time
	local currentTime = Constants.timeFunction()

	-- Set volume function
	local function setAudioVolume()
		-- Check muted
		if Globals.isAudioMuted then
			Constants.audioPlayer.Volume = 0
			return
		end

		-- Lerp volume based on time
		local volumeRange = Globals.audioFadeVolumeRange
		Constants.audioPlayer.Volume = rangeMap(
			currentTime - Globals.audioFadeStartTime,
			0, Constants.fadeTime,
			volumeRange[1], volumeRange[2],
			true
		)
	end

	-- Different states
	if Globals.audioState == AudioPlayingState.FadeOut then
		-- Check if fade out finished
		if currentTime > Globals.audioFadeStartTime + Constants.fadeTime then
			-- Set played audio (switches to "fade in" state)
			setPlayedAudio(Globals.targetAudio)
		end
	elseif Globals.audioState == AudioPlayingState.FadeIn then
		-- Check if fade in finished
		if currentTime > Globals.audioFadeStartTime + Constants.fadeTime then
			-- Switch to "playing" state
			Globals.audioState = AudioPlayingState.Playing
		end
	elseif Globals.audioState == AudioPlayingState.Playing then
		-- Do nothing
	end

	-- Set volume
	setAudioVolume()
end


----- Audio setup -----

setUpAudioWire = function()
	Constants.audioWire.SourceInstance = Constants.audioPlayer
	Constants.audioWire.TargetInstance = Constants.audioDeviceOutput
end

toggleMute = function()
	setIsMuted(not Globals.isAudioMuted)
end

setIsMuted = function(isMuted: boolean)
	Globals.isAudioMuted = isMuted
	Constants.music_uis.creditsLabelDarken_uiGradent.Enabled = isMuted
	Constants.music_uis.musicState_textLabel.Text = if isMuted then "Muted" else "Now playing"
end


----- Event functions -----

onMusicBindableEvent = function(action: string, ...)
	if action == "SetAudio" then
		setTargetAudio(...)
	elseif action == "PlayDefaultAudio" then
		setTargetAudio(Constants.defaultAudio)
	end
end


----- Auto scale -----

setScreenGuiAutoScale = function()
	local uiScale = Constants.music_uis.screenGui_uiScale
	local unitSize = (function()
		local result
		local value = uiScale:GetAttribute("UnitSize")
		if typeof(value) == "Vector2" then
			result = value
		else
			warn(`[Music]: No 'UnitSize' attribute (type 'Vector2') found for '{uiScale}'.`)
			result = Vector2.new(1200, 600)
		end
		return result
	end)()
	local scaleRange = (function()
		local result
		local value = uiScale:GetAttribute("ScaleRange")
		if typeof(value) == "NumberRange" then
			result = value
		else
			warn(`[Music]: No 'ScaleRange' attribute (type 'NumberRange') found for '{uiScale}'.`)
			result = NumberRange.new(0.6, 1)
		end
		return result
	end)()
	AutoUIScale.setScreenGuiAutoScale(Constants.music_uis.music_screenGui, uiScale, unitSize, scaleRange)
end


----- Main -----

local function main()
	-- GUI auto scale
	setScreenGuiAutoScale()

	-- Music event
	Constants.musicBindable.Event:Connect(onMusicBindableEvent)

	-- Mute button
	Constants.music_uis.icon_imageButton.Activated:Connect(toggleMute)
	setIsMuted(false)

	-- Music playing loop
	RunService.Heartbeat:Connect(musicLoopFrame)

	-- Connect wire
	setUpAudioWire()

	-- Set default audio
	setTargetAudio(Constants.defaultAudio)
end


---------- Calling function ----------

main()

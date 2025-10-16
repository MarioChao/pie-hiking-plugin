# Logs


## [v1.3.0] Hike Checkpoints Small Update | 2025/10/16

Hike checkpoints update:
- Changed the delay for setting `CFrame` from `task.wait(0.1)` to `RunService.Heartbeat:Wait()`.
- Added `Humanoid.HipHeight` to the vertical spawning position.


## 2025/07/26

Added new button for baking a beginner pie.

Added background colors for the plugin dock widget.

Renamed project to lower-kebab case.


## 2025/06/28

Added `LoopRegion` and `PlaybackRegion` configurations for `MusicZones`.


## 2025/06/09

Fixed pie not setting up correctly when `PieHikingModules` or `PieHikingServerStorage` isn't found in their respective container services.


## 2025/05/26 - 05/28

Added `PieMapKit_Audio` folder in `SoundService` to play background music.

Added `MusicZones`, client objects that change the background music while the player is touching the zone.<br>
For different music, the old audio will fade out before the new one fades in.

Music zone attributes:
* Audio_AssetId (number)
* Audio_PlaybackSpeed (number)
* Audio_Volume (number)
* Zone_Priority (number)


## 2025/03/10

Modified **Set up Pie** to prevent customizable files from being overwritten.

Moved files in `ReplicatedStorage` to the subfolder `PieMapKit_SharedStorage`.

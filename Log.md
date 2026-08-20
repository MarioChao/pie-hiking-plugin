# Logs

TODO:
- Simplify code for activators (ex: touch, zone).
- Revamp music system.

## [v1.9.2] Musi gui adjustments | 2026/08/20

Adjusted the music gui auto scale to `UnitSize` of 1200x600 and `ScaleRange` of (0.6, 1).

Set the music screen gui display order to 50.

## [v1.9.1] Readme credits | 2026/08/19

Added dependencies and a special thanks to [EToH Kit](https://etohgame.github.io/kit/) to the README credits.

Added the [pie setup video guide](https://www.youtube.com/shorts/IdNriG-9SFE) to README.

## [v1.9.0] Music gui | 2026/08/18 - 08/19

Added a music `ScreenGui`:
- Displays the artist and title of the playing music via [AssetService](https://create.roblox.com/docs/reference/engine/classes/AssetService).
- Allows muting by clicking on the icon.
- Easily customized through `StarterGui > MapKitMusic_ScreenGui`.

Added wally import for [PresetStarterGui](https://github.com/MarioChao/preset-starter-gui) for setting up preset guis from the `StarterGui` container.

Added new `AutoUIScale` module for automatically setting `UIScale.Scale` based on screen gui's size.

Fixed wiring of audio instances.

## [v1.8.0] Map kit type check + Script cleanup | 2026/08/15

Added typing for map kit.
- Modified `default.project.json` to synchronize `ReplicatedStorage` and `ServerScriptService` from the map kit.
- Moved plugin-only project to `dev.project.json`.

Cleaned up several map kit scripts to follow the "validate-services-imports-types-constants-globals-functions-module" section format.

Map kit scripts are no longer disabled initially.

## [v1.7.4] Zipline transport v0.7.1 | 2026/08/14 (2)

Migrated zipline transport to v0.7.1, which fixes cleaning up errors when ziplines are unloaded too quickly.

## [v1.7.3] Scoped loading | 2026/08/14 (1)

All map objects are now loaded when under [Workspace](https://create.roblox.com/docs/reference/engine/classes/Workspace) and unloaded otherwise.
- [Zipline transport](https://github.com/MarioChao/zipline-transportation-system) updated to v0.7.0.
- [ContainerMechanic](https://github.com/MarioChao/container-mechanic) v0.2.0 with valid ancestors for `LightingZones` and `MusicZones`.
- [ScopedCollection](https://github.com/MarioChao/scoped-collection) v1.0.0 with valid ancestors for all other objects.

Fixed legacy music zones breaking if missing some attributes.

## [v1.7.2] Zipline transport v0.5.0 | 2026/08/05

Migrated zipline transport to v0.5.0, which fixes major desyncs and adds end reverse waiting.

## [v1.7.1] Heart pie v2.0.3 | 2026/08/03

Migrated pie tool to v2.0.3, which fixes pie sticking to welded players.

## [v1.7.0] Zipline transportation system | 2026/08/02

Added ziplines.
- Imported [ZiplineTransport](https://github.com/MarioChao/zipline-transportation-system) v0.4.2 through wally.

## [v1.6.0] Priority zone group migration | 2026/07/24

Migrated `LightingZones` and `MusicZones` to use [PriorityZoneGroup](https://github.com/MarioChao/priority-zone-group).
- Uses [ContainerMechanic](https://github.com/MarioChao/container-mechanic) with tags on child configurations.
  - Separate configs: `LightingZoneConfig` and `MusicZoneConfig`.
- Lighting & music are in different zone groups, meaning 1 zone folder can have separate zone priorities for lighting and for music.

Legacy tags (`LightingZone` and `MusicZone`) are still supported.
- The kit converts them into `LightingZoneConfig` and `MusicZoneConfig`.

## [v1.5.1] Pie custom kit button | 2026/06/22 (2)

Added new button for inserting the [pie customization kit](https://create.roblox.com/store/asset/135707550833588/).

Removed button for inserting the pie package.

## [v1.5.0] Heart pie v2.0.2 + Refactored map kit | 2026/06/22 (1)

Migrated pie tool to v2.0.2.

Renamed `PieMapKitScripts` to `PieMapKit_ServerScripts`.

Refactored map kit audio:
- Renamed `PieMapKit_Audio` to `MapKit_Audio`.
- Moved it from `SoundService` to `ReplicatedStorage > PieMapKit_SharedStorage`.

Refactored map kit player scripts:
- Renamed `PieMapKit_PlayerScripts` to `MapKit_PlayerScripts`.
- Moved it from `StarterPlayerScripts` to `ReplicatedStorage > PieMapKit_SharedStorage`.

Renamed other shared storage instances:
- Renamed `PieMapKitModules` to `MapKit_Modules`.
- Renamed `PieMapKitEvents` to `MapKit_Events`.

Increased delay for hike checkpoints from 1 `RunService` heartbeat to 0.3 seconds.

Implemented wally for [UIUtil](https://wally.run/package/mariochao/ui-util).

## [v1.4.1] Heart pie v2.0.1 | 2026/06/15

Migrated pie tool to v2.0.1.

## [v1.4.0] Heart pie v2.0.0 | 2026/06/06

Migrated to Heart Pie v2.0.0.

Added new button for inserting the pie module folder.

Refactored `PieTool` to use `cloneReparentRecursive()` for setting up container scripts.

Cleaned a few scripts.

Removed wally.

## [v1.3.9] Pie package update | 2026/03/28

Migrated to Heart Pie package:
- Uses [Heart Pie v1.0.14](wally.run/package/mariochao/heart-pie?version=1.0.14) on wally.
- No longer uses `game:GetObjects()`.

Added new button for inserting the pie package.

Slightly refactored the `PieTool` module script.

Slightly adjusted the user interfaces.

## [v1.3.8] Pie throwing direction fix | 2026/02/28

Fixed pies launching in the direction of the accessories and tools of other players.
- Collision groups are now set on all descendant parts (instead of just the child parts) of other player characters.
- Parts in the "LocalPlayer" and "OtherPlayers" collision groups are automatically set to "Default" when unparented from a player character.

## [v1.3.7] Improved position teleporters | 2026/02/23

New position teleporter attributes:
- `IsServerSided` to allow long-distance teleporting in streaming-enabled places.
- `TransitionTime` to fade players to the destination.

## [v1.3.6] Lighting small fix | 2025/12/21

Last applied lighting config is now stored & retrieved from `UpdateLighting`.

Server-sided lighting update is now applied on each client separatedly (tweened), then applied on the server instantly.

Fixed default post-processing effects having significant intensities and other effects.

## [v1.3.5] Lighting zones + UIUtil invisible + Small fixes | 2025/12/20

Added `LightingZones`, client-sided zones that change the lighting according to a child "LightingConfig" `ModuleScript`.

`Invisible` tag now hides more variety of instances as well (ex: GUIs, decals) using `UIUtil`.

Default post effects no longer tween from `Instance.new()` values for initial lighting update.

## [v1.3.4] Tweened lighting effects | 2025/12/19

Lighting effects are now tweened when possible.

Unspecified lighting effects will now be reverted to the default state.

## [v1.3.3] Improved map & music + Client lighting | 2025/12/12

Improved map system:
- Dream folders can now be recognized by adding the "DreamFolder" tag.
  - You can now either add the "DreamFolder" tag or set the "DreamDifficulty" attribute.
- New dream folder attribute `AutoUnload`:
  - When enabled, the dream folder will unload (stored in `ServerStorage`) if it's not the default folder.
  - When disabled, the dream folder will remain in `workspace`.

Improved music system:
- Music zones:
  - The `AssetId` attribute now accepts either `number` or `string`.
  - New attribute `FromSound` - when enabled, audio info is from a child `Sound` instance under the `MusicZone` folder.
- Default music:
  - The plugin will set up a `Sound` under `PieMapKit_SharedStorage` called `Custom_DefaultMusicSound`.
    - This instance won't be replaced by the plugin, meaning you can now refresh the map kit without having to modify the default music.

Added support for modifying lighting on the client side (in the `UpdateLighting` module).
- By passing a `Player` as the second parameter to `applyLightingConfig`, the `Lighting` will only be changed for that specific `Player`.
- This will be useful for `LightingChangers` in the future.

## [v1.3.2] Invisible | 2025/11/11

Added `Invisible`:
- A simple way to make parts invisible to clients.
- Note: this sets `LocalTransparencyModifier` to 1 on all descendant parts.

## [v1.3.1] Minor changes | 2025/11/11

Prefixed "[Load Lighting]" to `LoadLighting`'s debug print.

Some other no-effect modifications.

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

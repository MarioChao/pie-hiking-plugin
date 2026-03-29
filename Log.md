# Logs

TODO:
- Simplify code for activators (ex: touch, zone).

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

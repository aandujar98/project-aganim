# Project Aganim

Project Aganim is a 2D top-down action-adventure RPG inspired by The Legend of Zelda: A Link to the Past, set in modern fictional Japan. The visual target is pixel art.

## Engine and language

- Godot 4.x; currently validated with **Godot 4.7.2 stable**.
- GDScript; no plugins or external dependencies.
- Internal resolution: **384 × 216**.
- Viewport stretch, preserved aspect ratio, and integer scaling; default window size is 1152 × 648 (3×).
- Nearest-neighbor texture filtering and 2D transform pixel snapping.
- The existing Mobile renderer is preserved.

## Current phase

**Phase 6 — Reusable Dungeon Foundation.** Phases 0–5 have passed. DevDungeon is a placeholder systems prototype with runtime dungeon state, keys, persistent doors/switches/chests, enemy-clear rooms, an Ember Gauntlet puzzle, and configured Slime mini-boss/boss encounters. Existing movement, combat, interaction, inventory, and room travel are preserved. Progress survives room travel and overworld re-entry during the current game session. Disk saves and Phase 7 quests are not implemented.

The starting speed is 90 pixels per second, adjustable through the Player's exported `movement_speed`. `Input.get_vector()` prevents faster diagonals and preserves gamepad analog strength. Movement starts and stops immediately. Facing follows the stronger axis; equal diagonals use the vertical direction. Idle retains the last facing direction. The existing polygons remain placeholder art, with a directional marker and discrete one-pixel walk bob driven by AnimationPlayer.

## Open and run

1. Open Godot 4.7.2 (or a compatible Godot 4.x version).
2. In Project Manager, select **Import**, choose this repository's `project.godot`, and open the project.
3. Open `game/main/dev_test.tscn` in the FileSystem dock.
4. Press **F6** (Run Current Scene) to run the movement, combat, and interaction sandbox. Move with WASD, arrows, a gamepad left stick, or D-pad.

F5 runs the preserved `game/main/main.tscn` and outdoor test district using the same updated Player; that scene does not contain combat enemies. The startup scene has not been replaced.

DevTest has open space, three original blocks, boundary walls, an L-shaped corner, and a 28-pixel gap between the central walls. Follow the horizontal path through the gap. Verify wall blocking, diagonal wall sliding, corners, four idle facings, and camera following across the 768 × 432 sandbox. Collision is an editable 18 × 10 rectangle at the feet. Camera smoothing stays off; camera positions round to whole world pixels while physics positions remain continuous.

Placeholder colors and shapes are not final protagonist art. Animation walks reflect actual movement; pushing straight into a wall returns to idle while retaining the attempted facing.

## Combat test

1. Open `game/main/dev_test.tscn` and run the current scene with F6.
2. Walk down the existing path toward the first Slime in the lower-left open area. The second is in the lower-right area, beyond the gap and corner tests.
3. Tap a movement direction and release it to set facing, then press Space, J, or the gamepad south face button to slash. Try approaching a Slime from all four sides.
4. Observe the yellow sword area, brief movement lock, enemy recoil, and tint. Each swing can damage a target once; release and press attack for the next swing. Three successful hits defeat a Slime.
5. Let a Slime approach. Its red contact attack deals one health, pushes the player back, and starts a brief red tint followed by invulnerability flashing. The small debug overlay shows player health/state; set DevTest's `show_combat_debug` to false to hide it.
6. Test attacks and knockback near walls. The sword has limited reach and world obstruction checks. Keep using the narrow gap and corners to verify movement.
7. At zero health, the player dims and control stops. Stop the scene (F8) and run it again (F6) to restart. There is no automatic respawn or Game Over menu.

Starting values: player health 6, sword damage 1, Slime health 3, Slime damage 1. The sword locks movement for 0.25 seconds and is active for its first 0.10 seconds. Player invulnerability lasts 0.75 seconds; Slime invulnerability lasts 0.25 seconds. Slimes use a 120-pixel detection radius, direct 35-pixel/second chase, 24-pixel attack distance, and a 1-second attack cooldown. These are exported tuning values, not permanent balance decisions.

Placeholder attacks use visible Area2D shapes and code timing, rather than final sword art. Slimes use direct chasing without pathfinding and can get stuck on obstacles. Combat affects only health and local actor states; combat adds no drops, XP, abilities, or advanced combat behavior. Inventory/healing now integrates through Phase 5.

## World interaction test

1. Open `game/main/dev_test.tscn`, press F6, and follow the horizontal path east through the central gap. The blue-gray interaction section is in the upper-right of the existing arena.
2. Approach the blue NPC from below, tap Up/W to face them, release movement, then press E or the gamepad west button. The input-neutral `Interact · Talk` prompt appears when a valid target is in front. Verify the Resident name and all three lines; release and press Interact for each next line and once more to close.
3. While talking, try movement and sword input. Neither should run. Hold Interact or let a keyboard repeat; text should stay on the current line. Closing restores control. The panel stays near the screen bottom while the world camera follows.
4. Face the brown sign beside the NPC and Interact. It shows `Old Shrine → North` using the same panel, without a speaker. Press again to close.
5. Face the cyan unlocked door and Interact. Its leaf disappears and collision disables; walk through. The red door shows `It's locked.` and remains solid after closing the message.
6. Open the right gold/brown chest below the doors. Its lid lifts for 0.45 seconds while control locks, then it adds the Mysterious Shrine Charm to inventory and shows its reward through the shared dialogue panel. The chest to its left adds three Spirit Fragments. Close the message; the lid stays open. Each chest grants once while that scene instance lives.
7. Touch the two cyan bottle pickups and blue fragment in the lower-left of this section. They add two Small Healing Drinks and one Spirit Fragment to inventory, disappear only after successful addition, and do not block movement. The old temporary pickup counter is removed.
8. Test facing away and standing farther from objects; no interaction should start. Repeat the movement and combat tests below/above the section. Interaction is unavailable during attack, hurt, or death. Damage during dialogue cancels it; damage during chest opening cancels the animation without a reward and allows a later retry. Death cannot be cleared by closing a message.

Local doors/chests/pickups reset when DevTest restarts; restarting the running game also resets inventory. There is no save persistence. The NPC has no schedules, pathfinding, branching conversation, or final art. Dialogue uses whole lines without a typewriter effect. Other worlds must instance the shared dialogue UI and assign it to the Player's InteractionDetector, as DevTest does. Dialogue remains scene-local; transitions, item lookup, runtime inventory, and its screen use focused Autoloads. F5 continues to run the preserved original district.

Godot settings require no manual changes. In the editor, verify the 384 × 216 viewport still scales in whole pixels, dialogue text is readable without clipping at your window size, and the west face button matches your connected controller. Optional **Debug → Visible Collision Shapes** helps inspect interaction/body shapes. Physical controller testing remains a manual check; automated tests use Godot input events.

## Transition test route

1. If Godot was open while these files changed, reload/reopen the project once so the new `SceneTransitions` Autoload is registered. No display/input setting needs changing.
2. Open `game/world/districts/transition_test/test_exterior.tscn` and press **F6**. Earlier DevTest and F5's original startup district remain unchanged.
3. Walk east and north to the cyan door at the south side of the dark test house. Stand below it, face Up, and press E or gamepad west/X. The screen fades out for 0.25 seconds, loads the interior at `house_inside`, applies upward facing and 384 × 216 camera bounds, then fades in for 0.25 seconds. Input remains locked until fade-in finishes.
4. Face the interior's south cyan door from above and press Interact to return at `house_front`, facing down. Verify no immediate re-entry. Try movement, sword, and the sign in each scene to confirm control and Phase 3 UI still work.
5. In the exterior, walk into the blue zone near the east wall along the horizontal path. Room B loads at `from_west`, facing right, with 512 × 288 camera bounds. Walk into Room B's west blue zone to return at exterior `from_east`, facing left, with 768 × 432 bounds.
6. Repeat this route several times. There should be one Player, no flickering camera, no view beyond the room, and no automatic bounce. Holding movement/attack/interact during a fade must not perform those actions until control returns. Transition starts are rejected during dialogue, attack, hurt, and death; an automatic zone can wait for attack/hurt recovery.
7. Open the unchanged `game/main/dev_test.tscn`, run F6, and repeat its movement, Slime combat, NPC/sign/door/chest/pickup tests. These scenes are separate; no travel link was added to DevTest. Physical controller behavior and scaling at your chosen window size remain manual acceptance checks.

Each transition area has a WorldArea root, exactly one reusable Player instance, a CameraBounds node, unique SpawnPoint IDs including `default`, and a shared DialogueUI. Door/zone destination paths are Inspector properties. Spawn-facing priority is entrance override → enabled spawn direction → previous player facing. Coordinates round to whole pixels on arrival. Safe spatial placement, a 0.25-second arrival cooldown, and exit-before-retrigger guards prevent arrival loops.

The manager validates a loaded destination before removing the current scene. A missing requested ID warns and uses the scene's configured default; invalid scenes, missing defaults/bounds, or duplicate Players leave the source intact. Health/max health, remaining invulnerability, and facing transfer at runtime. Scene-local doors/chests/pickups/enemies may reset on reload. The Phase 5 inventory Autoload persists during travel; no save/world-state system is added. Transition destinations currently require the WorldArea contract; earlier standalone scenes have not been converted.

## Inventory and item test

1. Reload/reopen an already-open editor once to register `ItemDatabase`, `Inventory`, and `InventoryScreen` alongside `SceneTransitions`. No renderer/scaling change is needed.
2. Open `game/main/dev_test.tscn`, press F6, then press I or gamepad Back/Select. The new session starts empty and shows `Inventory is empty.` Close with the same action, Escape/gamepad east (B), or the focused Close button.
3. Follow the horizontal path east through the central gap to the interaction section. Touch the two bottle pickups at the lower left. Open inventory and verify Small Healing Drink ×2, its icon, category, description, and quantity.
4. Close inventory, take one hit from a Slime, retreat out of its attack range, and wait for hurt recovery. Reopen inventory, select the drink with arrows/D-pad or left stick, then press Enter/Space or gamepad south (A). It restores one health through HealthComponent and consumes one drink. Trying at full health shows `Health is already full.` and keeps the drink.
5. Collect the blue fragment beside the bottles. Face the left chest from below and press Interact; it gives three more fragments. Total is four. Open the right chest for one Mysterious Shrine Charm. Release/press Interact to close reward messages.
6. Verify the charm has no Use action, stays at quantity one, and cannot be consumed or removed. Use Tab/Shift+Tab or directional focus to reach category tabs, Use, and Close; left/right on the focused tabs filters All, Consumables, Key Items, or Materials/Collectibles. All navigation uses Godot UI actions; mouse is optional. Removing the last consumable keeps a valid selection or displays the empty category.
7. While inventory is open, try movement, sword input, world interaction, and scene travel. These remain locked. Opening is rejected during attack, hurt, death, active dialogue/chest interaction, or a transition. Enemies still simulate; incoming damage/death closes inventory safely without reviving or overriding the hurt state.
8. For manual runtime-persistence testing, stop the game, open `game/world/districts/transition_test/test_exterior.tscn`, and run F6. This is a new empty session. Walk right through the three sample pickups beside the starting point: two drinks, three fragments, and one charm. Note quantities, then enter/exit the house and travel east to Room B and back. Reopen inventory in each area; quantities must remain intact. Do not stop/restart between areas.

Item definitions live in `game/items/data/`, with 16 × 16 placeholder SVG icons in `art/items/`. Stable IDs are `small_healing_drink`, `shrine_charm`, and `spirit_fragment`; display names can change independently. Stackable drink/fragment entries cap at 99 per ID; additions above the remaining limit reject the entire amount. There is no slot limit. Nonstackable/key items are unique and a second copy is rejected. Failed pickups remain in the world (magenta diamond marks missing data/icons); step away and re-enter to retry. Failed chest rewards keep the chest closed, including an already-owned unique reward.

Inventory is session-only. Overworld chests/pickups may reset on scene reload even though inventory stays intact. Phase 6 adds separate runtime persistence for dungeon chests and keys; Small Keys do not enter inventory. There is no disk save persistence, shops, Yen, equipment, quest integration, discarding, sorting, hotbar, or item dropping. The original unused Phase 3 chest-message resource remains on disk for preservation and is no longer referenced by chest logic. Placeholder UI/physical-controller acceptance remains a manual check on the developer's display/device.

## DevDungeon test

Open `game/world/districts/transition_test/test_exterior.tscn` and press **F6**. Face the cyan DevDungeon door at **(580, 330)** from below and press **E** (gamepad west/X). F5 still runs the original startup scene.

Route: Entrance → Enemy room → Small-key room → Switch puzzle (east exit) → Dungeon item → Lieutenant → Boss Door → Dev Guardian → Completion → exterior.

Defeat both Slimes with Space/J, take healing drinks from the supplies chest, obtain the Small Key, and interact with the gold door to spend it once. Activate both blue switches with E. Open the Ember Gauntlet chest, then interact with the Ancient Brazier to open the north passage. Defeat the lieutenant, interact with the purple Boss Door, defeat the Guardian, then use the completion exit. Inventory (I) shows the unique Gauntlet under Key Items with the distinct Dungeon Item category and no Use button. Small keys appear only in the dungeon debug display.

Release and press E again to close chest/locked-door/brazier messages. Ordinary combat rooms and both boss encounters lock exits until all designated enemies die. Revisit rooms without stopping the game to verify persistent chests, doors, switches, clears, item ownership, and completion. See [Dungeon architecture and exact manual test route](docs/DUNGEONS.md).

Dungeon state is runtime-only. Death retains the existing stop/restart limitation; no checkpoint or Game Over screen is added. For a completely fresh test, stop and restart the game. The debug-only `DungeonManager.reset_dungeon(&"dev_dungeon")` clears dungeon state, then requires a room reload to rebuild enemies; it intentionally keeps inventory. An already-owned Gauntlet is acknowledged by its reset chest without creating a duplicate. Hide the room's DungeonDebug CanvasLayer to disable the development display.

Reload/reopen the project in an already-running editor to register DungeonManager. Review any unsaved editor tabs before reloading; do not save an old scene over the updated disk version. Verify crisp integer scaling, camera limits, controller interactions, and visual legibility on your display. No display, renderer, input-map, or startup-scene setting changed in Phase 6.

## Input defaults

Movement, attack, interact, and inventory actions are active. Other gameplay and menu actions remain configured only; their behavior is not implemented.

- Movement: WASD / arrows; gamepad left stick / D-pad.
- Attack: Space / J; south face button (Xbox A).
- Interact: E; west face button (Xbox X).
- Dodge: Shift / K; east face button (Xbox B).
- Sprint: Ctrl; left shoulder.
- Item: F; right shoulder.
- Ability: Q; north face button (Xbox Y).
- Inventory: I; Back / Select.
- UI confirm: Enter / keypad Enter / Space; south face button (A).
- UI back: Escape; east face button (B).
- UI navigation: arrows / Tab / Shift+Tab; D-pad / left stick.
- Map: M; right-stick click.
- Pause: Escape; Start / Menu.

F and Q are provisional keyboard defaults for item and ability. Gamepad labels depend on the device; mappings use Godot's standard button layout and accept any controller. Letter bindings use physical key positions. Game code should read named actions, not physical keys.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)
- [Dungeon foundation](docs/DUNGEONS.md)

Godot-generated `.godot/` data is ignored by Git. Keep source assets, `.import` metadata, and GDScript `.gd.uid` files under version control. Empty directories are not tracked by Git until populated.

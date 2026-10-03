# Project Aganim

Project Aganim is a 2D top-down action-adventure RPG inspired by The Legend of Zelda: A Link to the Past, set in modern fictional Japan. The visual target is pixel art.

## Engine and language

- Godot 4.x; currently validated with **Godot 4.7.2 stable**.
- GDScript; no plugins or external dependencies.
- Internal resolution: **640 × 360** (changed from 384 × 216 to match the visual target; see docs/ART_DIRECTION.md).
- Viewport stretch, preserved aspect ratio, and integer scaling; default window size is 1280 × 720 (2×).
- Nearest-neighbor texture filtering and 2D transform pixel snapping.
- The existing Mobile renderer is preserved.

## Current phase

**Phase 9 — Save / Load Foundation (implemented; awaiting editor acceptance).** Phases 0–8 have passed. Three manual save slots preserve the chosen name, location, player health/position/facing, inventory, Yen, quests, dungeon progress, configured world objects, and limited shop stock. Saves are versioned JSON with validation, safe replacement, and a previous-save backup. Existing managers remain authoritative during play. No autosave, cloud save, or later milestone is implemented.

The starting speed is 90 pixels per second, adjustable through the Player's exported `movement_speed`. `Input.get_vector()` prevents faster diagonals and preserves gamepad analog strength. Movement starts and stops immediately. Facing follows the stronger axis; equal diagonals use the vertical direction. Idle retains the last facing direction. AnimationPlayer drives 4-frame idle/walk/run clips in 8 sprite directions on `art/characters/player/player_spritesheet.png`; gameplay facing stays cardinal (see docs/ART_DIRECTION.md).

## Open and run

1. Open Godot 4.7.2 (or a compatible Godot 4.x version).
2. In Project Manager, select **Import**, choose this repository's `project.godot`, and open the project.
3. Open `game/main/dev_test.tscn` in the FileSystem dock.
4. Press **F6** (Run Current Scene) to run the movement, combat, and interaction sandbox. Move with WASD, arrows, a gamepad left stick, or D-pad.

F5 runs the preserved `game/main/main.tscn` and outdoor test district using the same updated Player; that scene does not contain combat enemies. The startup scene has not been replaced.

DevTest has open space, three original blocks, boundary walls, an L-shaped corner, and a 28-pixel gap between the central walls. Follow the horizontal path through the gap. Verify wall blocking, diagonal wall sliding, corners, four idle facings, and camera following across the 768 × 432 sandbox. Collision is an editable 12 × 8 rectangle at the feet (the Player origin). Camera smoothing stays off; camera positions round to whole world pixels while physics positions remain continuous.

Animation walks reflect actual movement; pushing straight into a wall returns to idle while retaining the attempted facing.

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

Local doors/chests/pickups reset when DevTest restarts; restarting without loading a slot starts fresh. Phase 9 saves restore inventory, Yen, quests, and shop stock; the ordinary DevTest objects still reset locally. The NPC has no schedules, pathfinding, branching conversation, or final art. Dialogue uses whole lines without a typewriter effect. Other worlds must instance the shared dialogue UI and assign it to the Player's InteractionDetector, as DevTest does. Dialogue remains scene-local; transitions, item lookup, runtime inventory, and its screen use focused Autoloads. F5 continues to run the preserved original district.

Godot settings require no manual changes. In the editor, verify the 640 × 360 viewport still scales in whole pixels, dialogue text is readable without clipping at your window size, and the west face button matches your connected controller. Optional **Debug → Visible Collision Shapes** helps inspect interaction/body shapes. Physical controller testing remains a manual check; automated tests use Godot input events.

## Transition test route

1. If Godot was open while these files changed, reload/reopen the project once so the new `SceneTransitions` Autoload is registered. No display/input setting needs changing.
2. Open `game/world/districts/transition_test/test_exterior.tscn` and press **F6**. Earlier DevTest and F5's original startup district remain unchanged.
3. Walk east and north to the cyan door at the south side of the dark test house. Stand below it, face Up, and press E or gamepad west/X. The screen fades out for 0.25 seconds, loads the interior at `house_inside`, applies upward facing and 384 × 216 camera bounds, then fades in for 0.25 seconds. Input remains locked until fade-in finishes.
4. Face the interior's south cyan door from above and press Interact to return at `house_front`, facing down. Verify no immediate re-entry. Try movement, sword, and the sign in each scene to confirm control and Phase 3 UI still work.
5. In the exterior, walk into the blue zone near the east wall along the horizontal path. Room B loads at `from_west`, facing right, with 512 × 288 camera bounds. Walk into Room B's west blue zone to return at exterior `from_east`, facing left, with 768 × 432 bounds.
6. Repeat this route several times. There should be one Player, no flickering camera, no view beyond the room, and no automatic bounce. Holding movement/attack/interact during a fade must not perform those actions until control returns. Transition starts are rejected during dialogue, attack, hurt, and death; an automatic zone can wait for attack/hurt recovery.
7. Open the unchanged `game/main/dev_test.tscn`, run F6, and repeat its movement, Slime combat, NPC/sign/door/chest/pickup tests. These scenes are separate; no travel link was added to DevTest. Physical controller behavior and scaling at your chosen window size remain manual acceptance checks.

Each transition area has a WorldArea root, exactly one reusable Player instance, a CameraBounds node, unique SpawnPoint IDs including `default`, and a shared DialogueUI. Door/zone destination paths are Inspector properties. Spawn-facing priority is entrance override → enabled spawn direction → previous player facing. Coordinates round to whole pixels on arrival. Safe spatial placement, a 0.25-second arrival cooldown, and exit-before-retrigger guards prevent arrival loops.

The manager validates a loaded destination before removing the current scene. A missing requested ID warns and uses the scene's configured default; invalid scenes, missing defaults/bounds, or duplicate Players leave the source intact. Health/max health, remaining invulnerability, and facing transfer at runtime. Scene-local doors/chests/pickups/enemies may reset on reload. The Phase 5 inventory Autoload persists during travel; Phase 9 adds separate snapshot restoration and explicitly configured world persistence, described below. Transition destinations currently require the WorldArea contract; earlier standalone scenes have not been converted.

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

Inventory remains authoritative at runtime and is included in Phase 9 manual saves. Overworld chests/pickups may reset on scene reload even though inventory stays intact. Phase 6 adds separate runtime persistence for dungeon chests and keys; Small Keys do not enter inventory. Phase 9 adds disk saves; equipment, discarding, sorting, hotbar, and item dropping remain absent. The original unused Phase 3 chest-message resource remains on disk for preservation and is no longer referenced by chest logic. Placeholder UI/physical-controller acceptance remains a manual check on the developer's display/device.

## DevDungeon test

Open `game/world/districts/transition_test/test_exterior.tscn` and press **F6**. Face the cyan DevDungeon door at **(580, 330)** from below and press **E** (gamepad west/X). F5 still runs the original startup scene.

Route: Entrance → Enemy room → Small-key room → Switch puzzle (east exit) → Dungeon item → Lieutenant → Boss Door → Dev Guardian → Completion → exterior.

Defeat both Slimes with Space/J, take healing drinks from the supplies chest, obtain the Small Key, and interact with the gold door to spend it once. Activate both blue switches with E. Open the Ember Gauntlet chest, then interact with the Ancient Brazier to open the north passage. Defeat the lieutenant, interact with the purple Boss Door, defeat the Guardian, then use the completion exit. Inventory (I) shows the unique Gauntlet under Key Items with the distinct Dungeon Item category and no Use button. Small keys appear only in the dungeon debug display.

Release and press E again to close chest/locked-door/brazier messages. Ordinary combat rooms and both boss encounters lock exits until all designated enemies die. Revisit rooms without stopping the game to verify persistent chests, doors, switches, clears, item ownership, and completion. See [Dungeon architecture and exact manual test route](docs/DUNGEONS.md).

DungeonManager remains authoritative at runtime and Phase 9 persists its snapshots. Death allows manual Load/New Game; no checkpoint or Game Over screen is added. For a completely fresh test, stop/restart without loading a slot, or choose New Game. The debug-only `DungeonManager.reset_dungeon(&"dev_dungeon")` clears dungeon state, then requires a room reload to rebuild enemies; it intentionally keeps inventory. An already-owned Gauntlet is acknowledged by its reset chest without creating a duplicate. Hide the room's DungeonDebug CanvasLayer to disable the development display.

Reload/reopen the project in an already-running editor to register DungeonManager. Review any unsaved editor tabs before reloading; do not save an old scene over the updated disk version. Verify crisp integer scaling, camera limits, controller interactions, and visual legibility on your display. No display, renderer, input-map, or startup-scene setting changed in Phase 6.

## A Small Favor quest test

Open `game/world/districts/transition_test/test_exterior.tscn` and press F6. Mrs. Sato is at (96, 105), west of the house. Face her and press E/gamepad west. Advance three lines, then choose Yes with Enter/Space/gamepad south; choose No to leave the quest available. The charm appears near the shrine at (176, 263) only after acceptance. Touch it, open the journal with L/L3, and verify the return instruction. Return to Mrs. Sato and finish all three lines to exchange the charm for two Small Healing Drinks and ¥500. Repeated conversations give post-completion dialogue and no additional reward.

DevTest also contains this reusable test area: Mrs. Sato at (640, 125), shrine/charm to her southeast at (720, 260)/(720, 283). Existing Slimes remain active. Journal controls lock the player, but enemies continue simulating; damage safely closes it. Use arrows/D-pad or Tab for focus, up/down to scroll focused details, and Escape/gamepad east to close. The journal has Active and Completed tabs. Quest items appear under inventory Key Items and have no Use action.

Enter/exit the house or dungeon without stopping to verify quest persistence and restoration of NPC/pickup state. Stop/restart starts fresh unless a saved slot is loaded. Reload an already-open editor to register QuestManager and QuestJournal; review unsaved tabs first. Display/rendering/startup settings are unchanged. See [QUESTS.md](docs/QUESTS.md) for contracts, edge cases, and the complete acceptance route.

## Kagami Mart shop test

Run `game/world/districts/transition_test/test_exterior.tscn` with F6. The HUD starts at **¥3,000**. Kagami Mart is northeast of the test house: face the cyan door at **(590, 120)** from below and press E/gamepad west. Inside, approach the counter at (272, 86), face the clerk, and interact. Advance “Welcome! Need anything?”, then select **Buy** or **Leave**. Confirm opens the shop without buying automatically.

Use Up/Down or D-pad to select; Enter/Space/controller south buys one. Tab/right reaches Buy/Leave buttons. Escape/controller east closes to player control. Small Healing Drink costs ¥300 (unlimited), Spirit Fragment costs ¥500 (stock three), and Energy Soda costs ¥250 (unlimited; heals one HP through existing item use). The shop shows price, owned count, stock, and insufficient-funds feedback. Movement, attacks, other menus, and travel stay locked; damage/death cancels safely.

Face the store's south door from above to exit. Re-enter without stopping: Yen, inventory, and limited stock persist. Complete A Small Favor to earn two drinks plus ¥500 once. Stop/restart starts fresh unless a saved slot is loaded. Reload an already-open editor after reviewing unsaved tabs to register Wallet, ShopManager, ShopScreen, and CurrencyHUD. See [ECONOMY.md](docs/ECONOMY.md) for exact test arithmetic, resource conventions, transaction guarantees, and limitations.

## Visual target: Sakura City

Open `game/world/districts/visual_test/visual_test_district.tscn` and press **F6**. This night district replicates the Sakura City gameplay mockup with original art:

- Sakura Station, with ticket gates and an attendant.
- A crossing to a shrine: a large torii over stone stairs, kitsune statues, 神社 banners and a small hokora.
- A paved main street with lantern lamps and utility-pole wires.
- A ramen/izakaya house with chōchin lanterns, a karaoke building and a konbini with vending machines.
- A canal with railings and floating petals, a train, and a crowd of NPCs.

Talk to the Resident (speech bubble) or the girl on the shrine stairs with E or gamepad west.

The HUD shows hearts, magic orbs, Yen, A/Y/X/R quick slots and the minimap. The bomb, potion and boots slots are presentation previews.

The internal resolution is now **640 × 360**, integer-scaled to a 1280 × 720 window. Older menus are centred and the dialogue panel sits at bottom-centre. Rooms smaller than the screen are centred on a dark background.

The rules, sizes, lighting technique and import workflow are in [ART_DIRECTION.md](docs/ART_DIRECTION.md).

## Input defaults

Movement, sprint, attack, interact, inventory, and quest journal actions are active. Other gameplay and menu actions remain configured only; their behavior is not implemented.

- Movement: WASD / arrows; gamepad left stick / D-pad.
- Attack: Space / J; south face button (Xbox A).
- Interact: E; west face button (Xbox X).
- Dodge: Shift / K; east face button (Xbox B).
- Sprint: Ctrl; left shoulder. Hold while moving to run (run animations, 135 px/s).
- Item: F; right shoulder.
- Ability: Q; north face button (Xbox Y).
- Inventory: I; Back / Select.
- Quest journal: L; left-stick click (L3).
- UI confirm: Enter / keypad Enter / Space; south face button (A).
- UI back: Escape; east face button (B).
- UI navigation: arrows / Tab / Shift+Tab; D-pad / left stick.
- Map: M; right-stick click.
- Pause: Escape; Start / Menu.

F and Q are provisional keyboard defaults for item and ability. Gamepad labels depend on the device; mappings use Godot's standard button layout and accept any controller. Letter bindings use physical key positions. Game code should read named actions, not physical keys.

## Manual saves and New Game — Phase 9

1. Review unsaved editor tabs before reloading the project so the new `WorldState`, `PlayerProfile`, `SaveManager`, and `SaveSlots` Autoloads register. F5 still launches the original Main scene.
2. Press **Escape** or controller **Start**. Choose a slot with arrows/D-pad, Tab to the name field, enter 1–24 characters, and choose **New**. An occupied slot requires confirmation; its previous file is replaced only by a later manual Save. The new game begins in TestExterior at default spawn with six health, ¥3,000, empty inventory, and clean progress.
3. Close other gameplay menus. Open Escape/Start and choose **Save**. It saves the **active** slot, regardless of the highlighted slot. Save requires a living player in normal gameplay in a WorldArea. There is no autosave, including at New Game or on quit.
4. Stop the game and run again. Escape/Start → select occupied slot → **Load** restores that slot. Metadata shows name, area, elapsed time, and last save in UTC. **Delete** requires confirmation and removes only the selected slot and its backup.
5. Keyboard Tab/Shift+Tab and arrows, Enter/Space, and controller focus/confirm/back work. Escape/Start closes the screen; controller east/B cancels. Name entry uses a keyboard; no controller text keyboard is added. The screen locks the player, while world simulation continues; damage cancels it safely.

Saves: `user://saves/slot_01.json` through `slot_03.json`; version **1**. On macOS this project normally resolves to `~/Library/Application Support/Godot/app_userdata/Project Aganim/saves/`. The prior valid primary is kept as `.json.bak`. Failed/corrupt loads preserve the current runtime and keep the file. There is no automatic backup recovery.

TestExterior's new southwest persistence row has a chest at (90, 330), a permanent door at (145, 330), a switch at (190, 350), and a one-time pickup at (95, 380). These opt into stable world IDs. Existing ordinary objects continue their earlier reset behavior. Dungeon objects retain DungeonManager ownership.

See [SAVE_FORMAT.md](documentation/SAVE_FORMAT.md) for the format, restore order, APIs, and exact cross-slot/quest/dungeon/shop acceptance routes. Automated disk/restart tests used a temporary project copy because this session could not write to the real Godot user-data save directory. Verify real `user://saves/` writes and physical-controller/layout behavior in the editor. Display, renderer, input bindings, and startup scene are preserved. Earlier Main/DevTest are standalone sandboxes; start New Game to enter the WorldArea save route.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)
- [Dungeon foundation](docs/DUNGEONS.md)
- [Save format and Phase 9 acceptance tests](documentation/SAVE_FORMAT.md)
- [Quest system and A Small Favor walkthrough](docs/QUESTS.md)
- [Yen, shops, and Kagami Mart](docs/ECONOMY.md)
- [Art direction (visual bible)](docs/ART_DIRECTION.md)

Godot-generated `.godot/` data is ignored by Git. Keep source assets, `.import` metadata, and GDScript `.gd.uid` files under version control. Empty directories are not tracked by Git until populated.

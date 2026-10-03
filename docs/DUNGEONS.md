# Reusable dungeon foundation — Phase 6

DevDungeon is a systems prototype, not final dungeon content. It uses placeholder polygons and a small SVG item icon. All implementation is Godot 4.x GDScript with the existing project folders and no dependencies.

## Composition and responsibilities

Rooms under `game/dungeons/dev_dungeon/` are WorldArea scenes: one Player, CameraBounds, scene-local DialogueUI, explicit SpawnPoints, walls, objects, an Enemies container, and a focused DungeonRoomController. Existing SceneEntrance/SceneTransitions handle travel and fades. Room scripts do not load scenes directly. WorldArea's optional `dungeon_id` sets active context only when the committed scene reaches `_ready()`; ordinary areas clear that context. Preflight instances have no state side effects.

DungeonManager is an Autoload under `game/dungeons/shared/`. It owns the active dungeon ID and per-ID state registry, key changes, persistent object flags, encounter/room completion, change signals, and a debug reset method. Inventory remains owned by Inventory; health/combat stay in the existing components. Consumers read DungeonState and mutate through manager methods so listeners receive updates. State dictionaries are in-memory references. Phase 9 serializes explicit snapshots, not these live references or scene nodes.

DungeonState extends RefCounted and contains `dungeon_id`, `small_keys`, four dictionaries (`activated_switches`, `unlocked_doors`, `opened_chests`, `cleared_rooms`), and booleans (`miniboss_defeated`, `boss_defeated`, `dungeon_item_obtained`, `completed`). `state_changed(dungeon_id)` and `active_dungeon_changed(dungeon_id)` keep objects/debug text current without puzzle polling.

## Stable IDs

IDs are explicit snake_case Inspector values, independent of display names, node paths, and instance IDs. Object IDs must be unique within their dungeon and state collection. Room IDs are unique within a dungeon. References deliberately reuse those values; never generate persistent IDs from node names at runtime. Spawn IDs remain local to their scene.

- Dungeon: `dev_dungeon`.
- Rooms: `dd_entrance`, `dd_room_01`, `dd_room_02`, `dd_room_03`, `dd_item_room`, `dd_miniboss_room`, `dd_boss_room`, `dd_completion`.
- Key door: `dd_door_room02_north`; Boss Door: `dd_boss_door`.
- Switches: `dd_switch_a`, `dd_switch_b`, `dd_brazier`.
- Chests: `dd_chest_room_01_supplies`, `dd_chest_room_02_key`, `dd_chest_item_room_item`.
- Item: `ember_gauntlet`; display name: Ember Gauntlet.
- Room arrival spawns: `default`, plus connected `from_north`, `from_south`, `from_west`, `from_east`.
- Exterior return spawn: `dungeon_return` at (580, 366), facing down.

A future dungeon gets its own stable dungeon ID and configured room/object IDs. Infrastructure contains no DevDungeon-specific Player branches or scene paths.

## Keys and doors

Small-key chest rewards call DungeonManager.add_small_keys for their configured dungeon. Keys never enter normal inventory. HUD/debug count and shared chest message provide feedback. Keys remain in that dungeon's state when the Player exits/re-enters during the same session.

DungeonLockedDoor is a shared Interactable with a StaticBody2D child. No key shows shared dialogue: `The door is locked.` With a key, the normal Player interaction lock is acquired, then `unlock_with_key` commits key decrement and door flag together before emitting a change signal. Repeat calls for the same unlocked ID consume nothing. Unlocked doors restore invisible visuals and disabled collision on room load.

BossDoor extends that door contract with a separate condition: mini-boss victory. It never spends a Small Key. In DevDungeon, interact with the purple door after the lieutenant dies; its stable unlocked flag then persists. Boss Keys are not implemented.

## Switches, barriers, and item puzzle

The primary switch implementation is **interaction-based**. Face a blue switch and use E/gamepad west. It sets a persistent switch ID, changes its placeholder color, and stops accepting repeat interactions. No separate attack receiver is added.

DungeonBarrier is a reusable StaticBody2D whose configured condition can be all switches in `required_switch_ids`, a specific cleared room, mini-boss victory, or dungeon completion. An empty switch list fails closed. It restores state on load and updates only on manager signals; collision updates are deferred safely. Room 3 requires both `dd_switch_a` and `dd_switch_b` to open the east passage.

AncientBrazier is a configured instance of the same switch scene, with a flame-shaped polygon, `required_item_id = ember_gauntlet`, and `The brazier is cold.` feedback. Without ownership it cannot activate. With ownership, interaction sets `dd_brazier`; the north passage opens and stays open. The item is never consumed. No fire magic, equipping, or fire propagation exists.

## Room clears and encounter locks

DungeonRoomController reads the designated Enemies container, validates every required enemy's HealthComponent, and connects each living enemy's existing `died` signal once. No hardcoded enemy count, enemy-state polling, or duplicate death implementation is used. The full remaining set must die before the room is cleared. Invalid enemy configuration fails closed.

A permanently cleared room removes its designated required enemies during reconstruction, before their next physics update. Non-clear-required rooms leave ordinary enemies free to respawn on reload; this distinction is configuration, not a global change to Slime behavior.

Room 1 locks both passages until both Slimes die. The lieutenant room seals the entrance and keeps the Boss Door closed during combat. The boss room seals both passages until victory. Arrivals spawn inside the arena, beyond the barrier, using existing transition locking. Horizontal and vertical wall segments meet their 48-pixel barriers without walkable gaps. No new checkpoint/death state is introduced.

Mini-boss encounter configuration sets both its room-clear flag and `miniboss_defeated` before broadcasting the update. DevLieutenant is the existing Slime scene with six health, speed 42, and scale 1.3. DevGuardian uses ten health, speed 28, scale 1.6, and attack damage two. Existing sword/hurtbox/HealthComponent behavior supplies combat; there is no new boss AI or boss health HUD.

Guardian death commits room clear, `boss_defeated`, and `completed` together. Both combat barriers open. The development display shows `The dungeon's power has faded.` Completion's north exit requires completed state and returns to the named exterior spawn. There is no story reward or Celestial Crest.

## Persistent chest and item rewards

DungeonChest extends the existing TreasureChest using reward-validation, reward-message, grant, and post-commit hooks. It preserves the original lid tween, scoped Player lock, shared dialogue, cancellation, capacity recheck, and damage/death safety. Each chest restores `is_open`, raised lid, and disabled interaction from its explicit persistent ID. Opening records its ID only after reward success; leaving/re-entry cannot grant another reward.

Three configured reward kinds are supported: ordinary inventory item, dungeon Small Key, and dungeon item. The supplies chest contains three Small Healing Drinks; the key chest contains one dungeon key; the item chest grants one Ember Gauntlet.

Ember Gauntlet uses ItemDatabase/ItemData/Inventory. Its description is `An ancient gauntlet radiating faint heat.` DUNGEON_ITEM is a separate category, forced unique even if accidentally marked stackable, protected from normal removal, and non-consumable. Inventory shows it under the existing Key Items filter with category label Dungeon Item and no Use button. The item chest marks dungeon-item ownership state and then presents the shared reward message. Nothing is hardcoded into Player.

Inventory overflow/invalid reward keeps a chest closed and retryable. Cancellation before grant gives nothing. A synchronous damage callback during successful grant still records the reward/chest and never starts late dialogue or revives the Player.

## Exact manual route

1. Open `game/world/districts/transition_test/test_exterior.tscn` and press F6. Review/reopen an already-open editor to register the new DungeonManager Autoload, preserving any unsaved tabs. F5 remains the original startup scene. Optionally collect the exterior healing drinks; this is a fresh runtime session.
2. Walk to (580, 366), face north toward the cyan DevDungeon door at (580, 330), and press E/gamepad west (X). Confirm the dungeon debug display, one Player, north-facing safe spawn, and camera following. Walk north to the cyan room exit and press E.
3. In Room 1, verify both red barriers block departure. Face the two Slimes and use Space/J/gamepad south (A) for sword slashes. Defeat both; both barriers disappear. Open the chest at (380, 180) from below for three drinks. Release/press E to close dialogue. Use I/gamepad Back inventory and confirm healing works after damage. Leave south and return north: enemies stay absent and the supplies chest stays open. Continue north.
4. In Room 2, try the gold north door without a key: it shows locked feedback. Close that message. Open the chest at (200, 130) for one Small Key; close its message. Count is one in dungeon debug UI and no Small Key appears in inventory. You can leave south/return to confirm preservation. Face the gold door near (256, 52) from below and press E. Count becomes zero, collision disappears, and repeat interaction cannot consume another key. Walk through to the cyan north exit and press E.
5. In Room 3, interact from below with the blue switches at (170, 100) and (320, 170). One alone leaves the east gate shut; both turn amber and open it. Leave south/return to confirm reconstruction if desired. Walk east through the passage and face right toward the cyan east exit near (486, 144), then press E.
6. In the item room, approach the brazier at (330, 120) and interact before opening the chest: `The brazier is cold.` Close dialogue. Open the chest at (205, 144), wait for the lid animation, and close the Ember Gauntlet reward message. Open inventory: exactly one Gauntlet appears in Key Items as Dungeon Item without Use. Close inventory. Interact with the brazier again: it lights amber and the north gate opens. Revisit via west/east if desired; chest, ownership, and brazier persist. Take the north exit.
7. In the lieutenant room, verify the entrance barrier and purple Boss Door prevent departure while the Slime variant lives. Sword attacks defeat it in six accepted hits; space attacks around its invulnerability/cooldown. Entrance opens and Mini changes to defeated. Face the purple north door and press E; it opens without using a Small Key. Revisit through south to confirm the lieutenant stays absent. Then take the cyan north exit.
8. In the Guardian room, both passages lock. Defeat the larger placeholder boss in ten accepted sword hits; dodge by walking out of its attack range and use saved drinks if needed. Boss changes to defeated, completion feedback appears, and both barriers open. Take the north exit into Completion.
9. In Completion, walk through the open north gate and use the cyan north exit. Confirm return to exterior at (580, 366), facing south; active dungeon context clears, while health, inventory/Gauntlet, and all dungeon progress remain intact.
10. Re-enter without stopping the game. Retrace the route: cleared enemies, lieutenant, and Guardian stay absent; supplies/key/item chests stay open; key/Boss doors, switches, brazier, and completion passage restore correctly. Completion feedback remains visible. This completes the Phase 6 dungeon route; Phase 7 quest testing is documented separately in QUESTS.md.

Movement remains WASD/arrows/stick/D-pad. Interactions and travel use named actions; no gameplay code depends on raw physical keys. Small-room camera limits apply using the existing 384 × 216 viewport. Check integer scaling, legibility, and physical controller behavior manually.

## Runtime lifecycle and debug reset

Leaving the dungeon clears active context but does not erase per-dungeon runtime state. SceneTransitions transfers current/max health, invulnerability, and facing; Inventory retains items. Phase 9 manual saves serialize keys, switches, doors, chests, cleared rooms, dungeon item, mini-boss/boss/completion state and saved room/position. Restart without loading starts fresh; loading reconstructs objects after the manager is restored. See [SAVE_FORMAT.md](../documentation/SAVE_FORMAT.md) for before/after-boss restart tests.

For development, call `DungeonManager.reset_dungeon(&"dev_dungeon")` from a temporary debug call. It only runs in debug builds and has no release UI. Then reload the room through the existing transition system to reconstruct enemies and closed chests. Reset does not remove Inventory items; a reset dungeon-item chest acknowledges an already-owned Gauntlet, marks the new dungeon state's ownership flag, and opens without duplicating it. Restart the game to test the cold-brazier acquisition route from scratch. Do not call reset during an active chest/transition animation.

The optional DungeonDebug CanvasLayer is easy to hide per room and updates only on state signals. It is temporary feedback, not a final dungeon HUD. There is no dungeon music or audio routing.

## Validation and limits

Validated on Godot 4.7.2 stable with headless import, full entry-to-exit/re-entry tests, reward/cancellation/capacity edges, actual Player movement against closed/open doors, wall-gap sampling, all-switch conditions, boss sword damage, room-clear signal registration/restoration, malformed-container fail-closed behavior, script warnings, and Phase 1–5 regression checks. Prototype scene startup/resource loading is checked separately. The test fixture deliberately triggers invalid-reward/configuration warnings; these are expected failure-path diagnostics.

The graphical preview and physical controller/display acceptance remain manual. The environment's previously observed macOS certificate lookup diagnostic and sandbox restriction on saving global editor preferences remain unrelated to project parsing. A separate graphical launch attempt exited with code 134 here; headless gameplay/resource validation passes. No project display/input/startup configuration changed beyond the new Autoload.

Death retains the existing Phase 2 combat behavior. Phase 9 additionally allows Escape/Start → Load an existing slot or New Game; no automatic respawn is added. No dungeon checkpoint, respawn, Game Over screen, difficulty balancing, final art/bosses, final Temple of Embers, story rewards, complex multi-room puzzles, dungeon map/compass/or Boss Keys are included in the dungeon foundation. Phase 9 adds manual disk saves separately. Phase 7 adds the separate quest framework documented in QUESTS.md.

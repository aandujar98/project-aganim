# Save format — Phase 9

## Location, slots, and version

SaveManager is the only file-path/I/O owner. Three slots use `user://saves/slot_01.json`, `slot_02.json`, and `slot_03.json`. On macOS, this project's user directory normally resolves to `~/Library/Application Support/Godot/app_userdata/Project Aganim/`. Use Godot's **Project → Open User Data Folder** to verify the actual location. Files remain outside the repository; `.godot/` is still ignored.

Current format: **save_version 1**. UTF-8, readable JSON, maximum 2 MiB per file. A previous valid primary is copied to `slot_01.json.bak` before replacement. `slot_01.json.tmp` is a temporary write, never an accepted slot. Other slots follow the same naming rule.

## Ownership and APIs

Existing runtime managers remain authoritative while playing; save files are snapshots. Authored ItemData, QuestData, ShopData, PackedScenes, live Nodes, signal connections, timers, UI state, and input bindings are not serialized.

SaveManager exposes:

- `save_game(slot = -1, overwrite_confirmed = false) -> bool`: defaults to active slot; a different occupied target requires confirmation.
- `await load_game(slot) -> bool`: preflight and controlled scene restoration.
- `await new_game(slot, player_name, overwrite_confirmed = false) -> bool`: clean defaults and start scene; occupied slots require confirmation.
- `delete_save(slot, confirmed = false) -> bool`: explicit confirmation; selected primary/backup/temp only.
- `has_save(slot)`, `get_slot_metadata(slot)`, `validate_slot(slot)`.
- `dump_current_save_snapshot() -> Dictionary`: development inspection, no disk write.
- `active_slot`, `busy`, `last_error`; signals `game_saved(slot)`, `game_loaded(slot)`, `slots_changed`, `operation_failed(message)`.

`validate_slot` validates JSON/schema and scene existence; full WorldArea/Player/spawn/bounds preflight occurs at Load. It does not modify runtime state. There are no debug save keybindings.

Inventory, Wallet, QuestManager, DungeonManager, WorldState, ShopManager, and PlayerProfile expose `to_save_data()`, `load_save_data(data)`, and `reset_runtime_state()`. DungeonState exposes snapshot/load, with manager-owned reset. SaveManager orchestrates these APIs without maintaining copies of their internal runtime state.

## Top-level schema

This abbreviated example is valid version-1 data; absent optional sections are initialized safely:

```json
{
  "save_version": 1,
  "metadata": {
    "last_saved_timestamp": "2026-10-02T19:30:12",
    "current_area_name": "TestExterior"
  },
  "profile": {"name": "Kai", "playtime_seconds": 4212},
  "player": {
    "scene": "res://game/world/districts/transition_test/test_exterior.tscn",
    "position": {"x": 300, "y": 300},
    "facing": {"x": 0, "y": 1},
    "current_health": 3,
    "max_health": 6
  },
  "inventory": {
    "items": [{"item_id": "small_healing_drink", "quantity": 4}]
  },
  "wallet": {"yen": 2450},
  "quests": {},
  "dungeons": {},
  "world_state": {
    "opened_chests": [],
    "opened_doors": [],
    "activated_switches": [],
    "collected_pickups": [],
    "defeated_unique_enemies": [],
    "story_objects": []
  },
  "shop_stock": {"dev_convenience_store": {"spirit_fragment": 1}}
}
```

Profile name/playtime appear only once, as actual PlayerProfile state. Slot metadata combines these with version and area/timestamp; it does not introduce a second name authority. Timestamp is UTC, formatted `YYYY-MM-DDTHH:MM:SS`. Playtime is floored seconds and counts time while a scene is running, including menus. It is not a real-time clock used for gameplay.

## Player and inventory

Required player data: existing `res://game/...tscn` scene path and a valid profile/name. Loading requires a WorldArea with exactly one Player, valid camera bounds, and default spawn. Missing position uses that spawn; missing facing uses down. Explicit vectors must contain finite numbers; facing must be one of four cardinal unit vectors. Positions round to integer pixels. A missing/invalid scene fails clearly; it never silently substitutes another location.

Health restores directly through the existing Player/HealthComponent runtime API. Max health clamps to 1–100; current health clamps to 1–max. Defaults are six/full health. Dead gameplay cannot be saved. Invulnerability, knockback, attacks, transient movement, animation time, and interaction state are not saved. The reconstructed Player returns to NORMAL with no invulnerability.

Inventory saves only registered item IDs/quantities in `inventory.items`. Restore resolves ItemDatabase, skips unknown IDs with warnings, rejects nonnumeric/negative amounts, caps stacks at ItemData.quantity_limit(), and honors unique items. The first valid duplicate entry wins. Restore emits inventory refresh, never item-added or gameplay collection events. Wallet restores bounded integer Yen (0–999,999,999); missing data uses configured starting Yen, currently ¥3,000. HUD updates via existing currency signals.

## Quests

```json
"quests": {
  "a_small_favor": {
    "state": "ACTIVE",
    "objective_progress": [1],
    "objectives_complete": true
  }
}
```

Keys are QuestDatabase IDs. State names are UNAVAILABLE, AVAILABLE, ACTIVE, COMPLETED, FAILED. Unknown IDs warn and are ignored. Unknown states fall back to UNAVAILABLE; availability is recomputed from completed prerequisites after all quests restore. ACTIVE/FAILED progress uses definition order and clamps each count to 0..required_amount. COMPLETED remains terminal and restores complete progress. Missing quests initialize from authored definitions. Ready-to-turn-in is recomputed from validated progress plus the existing definition; the saved objectives_complete flag is descriptive rather than trusted authority.

Restore grants no rewards, emits no accepted/completed notifications, and clears queued completion callbacks from the previous runtime using a restore epoch. Normal future gameplay still follows the existing reward rules. NPC dialogue and quest pickups query QuestManager/Inventory on reconstruction; NPC scene nodes are not separately saved.

## Dungeons

```json
"dungeons": {
  "dev_dungeon": {
    "small_keys": 1,
    "activated_switches": ["dd_switch_a", "dd_switch_b", "dd_brazier"],
    "unlocked_doors": ["dd_door_room02_north", "dd_boss_door"],
    "opened_chests": ["dd_chest_room_01_supplies", "dd_chest_room_02_key", "dd_chest_item_room_item"],
    "cleared_rooms": ["dd_room_01", "dd_miniboss_room"],
    "dungeon_item_obtained": true,
    "miniboss_defeated": true,
    "boss_defeated": false,
    "completed": false
  }
}
```

DungeonManager owns every visited dungeon's keys/flags/terminal state. Counts are bounded nonnegative integers; invalid arrays/flags default empty and nonboolean terminal values default false. The active dungeon context is reconstructed from the loaded WorldArea; it is not independently saved. Scene and player position preserve the current room. Inventory independently owns the actual Ember Gauntlet item. Dungeon chests, switches, locked/Boss Doors, cleared rooms, and mini-boss/boss encounters query DungeonManager before gameplay begins. No dungeon flags are duplicated into WorldState.

## World state and stable IDs

WorldState contains category arrays for opened_chests, opened_doors, activated_switches, collected_pickups, defeated_unique_enemies, and story_objects. IDs must be explicit stable strings, unique across the whole world within each category, independent of node names, display labels, node paths, and instance IDs. IDs are validated on load (nonempty, at most 160 characters); unknown future flags are harmless to scenes that do not query them. Never recycle an ID for another permanent object. Rename/removal policy belongs in future migrations.

TreasureChest, physical Door, Pickup, and Slime expose optional `persistent` and `persistent_id`; persistence defaults false. PersistentSwitch always requires an ID. Missing IDs fail closed with a warning. Chests flag only after reward success; pickups flag only after successful addition; permanent doors flag on opening; switches flag on interaction; unique enemies flag on actual death. Their `_ready()` reconstructs state from WorldState. Ordinary temporary pickups/enemies and unconfigured scene-local objects retain their prior behavior.

TestExterior includes `exterior_supply_chest`, `exterior_test_door`, `exterior_test_switch`, and `exterior_soda_pickup`. Quest charm persistence remains QuestManager + Inventory, as before; DungeonManager remains the dungeon authority.

## Shop stock

`shop_stock` maps ShopData ID → item ID → limited remaining count. Only limited entries are saved; unlimited items derive stock -1 from definitions. Restore rebuilds defaults for every known shop, then clamps saved limited stock to 0..configured initial stock. Unknown shops/items are ignored; missing values use authored initial stock. ShopData resources and prices are never mutated or serialized. The existing shop screen reads the restored service when opened, including SOLD OUT.

## New Game, save, and restore order

New Game validates slot/name (trimmed 1–24 characters), requires confirmation if occupied, and constructs a version-1 default snapshot. It starts TestExterior at default spawn, six/full health, empty inventory, configured ¥3,000 wallet, initial quest availability with no active/completed quest, empty dungeon/world state, full initial shop stock, and zero playtime. The active slot is assigned after successful restoration. **New Game does not write a save**; an occupied slot's old file remains until manual Save.

Manual Save requires an active slot, current WorldArea, a living NORMAL Player, no input/transition lock, no fade, and idle inventory/wallet/shop/quest transactions. Other gameplay UI must close first; the Save button releases its own scoped menu lock before taking the snapshot. Saving never captures a partially loaded destination, death, hurt, attack, dialogue, or mid-reward state.

Load order:

1. Read/parse/version/schema checks, with no runtime mutation.
2. Instantiate destination off-tree; preflight WorldArea, one Player, default spawn, and camera bounds.
3. Freeze/fade source. If an external scene replacement interrupts the fade, cancel before applying manager state. Detach/remove source, so old objects cannot react to restoration signals.
4. Reset QuestManager first to invalidate old callbacks; reset Wallet, Inventory, DungeonManager, WorldState, ShopManager, PlayerProfile.
5. Apply Wallet → Inventory → QuestManager → DungeonManager → WorldState → ShopManager → PlayerProfile snapshots.
6. Add disabled destination: `_ready()` sees restored managers and reconstructs persistent objects; scene initializes active dungeon context.
7. Restore Player position/facing/health, animation, and immediate camera placement. Register physics, fade in, return NORMAL/input, and enable destination simulation.
8. Assign active slot and emit game_loaded. Ordinary transition-arrival events are suppressed during load to avoid replaying quest objectives.

Switching slots always resets first; omitted fields cannot inherit a previous slot's data.

## Safe writes, failures, and migrations

Serialize only on manual save. Write same-directory `.tmp`, flush/check the write error, close, back up the previous schema-valid primary, then rename temporary → primary. Any write/backup/replacement failure reports an error and leaves the prior primary. Rename replacement was tested on the available macOS Godot build. This guards the primary from ordinary failures; it is not a guarantee against every power-loss/filesystem failure, and no directory fsync is performed. Backups are not loaded automatically or exposed through a restore UI in Phase 9.

Missing/invalid slots, malformed JSON, oversized files, unsupported/newer versions, invalid required data, bad vectors, missing scenes, or invalid scene contracts return false with useful last_error/UI feedback. Corrupt files are retained and labeled Corrupted Save when schema parsing fails. Manager state is untouched on preflight failure. Optional omitted sections default cleanly; present sections with a wrong container type fail preflight. Unknown extra fields are ignored. Invalid safe leaf values are defaulted/clamped by their owner.

SaveSchema._migrate_save_data is the single future sequential migration hook. Version 1 is the first format and has no older supported versions; missing version and newer versions fail rather than being guessed. When a later format ships, add explicit version-by-version upgrades and tests before accepting it. Unknown/new optional fields in supported version-1 saves do not invalidate the whole file.

## Exact manual acceptance routes

### Menu, slot isolation, and real save directory

1. Reload project after reviewing unsaved editor tabs. F5 → Escape/Start. Verify three Empty labels when no saves exist.
2. Select Slot 1, enter Akira, New. Confirm TestExterior, six health, ¥3,000, empty Inventory, no active/completed quests, default stock. Save via Escape/Start → Save; inspect `user://saves/slot_01.json` through Open User Data Folder.
3. Complete A Small Favor using the route below; save Slot 1 with its rewards/high Yen. Reopen menu, select occupied Slot 1 → New. Cancel confirmation; verify file and runtime unchanged.
4. Select Slot 2, enter Mika, New; verify ¥3,000, empty inventory/progress, full shop stock. Save. Load Slot 1: completed quest and saved Yen/items return. Load Slot 2: no Slot 1 progress remains. Load Slot 1 again: its data is intact.
5. Stop the application and run again. Load Slot 1: verify name/scene/position/facing/health/items/Yen/progress. Move and attack; open/use inventory and dialogue. Confirm slot metadata time/name/area/UTC date.
6. With Slot 1 active, highlight Slot 2 and choose Save: only active Slot 1 is saved. Delete Slot 2 → cancel first, then explicitly Confirm. Verify Slot 1/3 files unchanged and Slot 2 Empty. This removes only selected slot files.
7. Test arrows/D-pad/stick focus, Tab/Shift+Tab, Enter/Space/controller south, east/B cancellation, Start/Escape toggle, and Escape while editing the name. Confirm mouse-free operation except keyboard name entry. Test damage cancellation and rejection of saving during combat/menus/fades/death. Real controller layout and display readability remain manual.

### A Small Favor: ready and completed

1. Start a fresh named slot in TestExterior. Face Mrs. Sato (96,105), Interact through her lines, choose Yes. Inventory is empty and Yen is ¥3,000.
2. Touch Old Lucky Charm near (176,263). Journal shows ACTIVE, 1/1, ready-to-turn-in; charm exists. Save outside dialogue, note position/facing/health, stop application, rerun, Load that slot.
3. Verify charm retained, ready journal, ¥3,000, no two-drink/¥500 reward yet. Mrs. Sato's first ready line is `You found it!`.
4. Complete her turn-in dialogue: charm removed, two drinks and ¥500 granted exactly once. Save, stop application, rerun, Load.
5. Verify COMPLETED, no charm, same drink quantity, ¥3,500, and post-completion dialogue `That charm has brought me luck for years.` Repeat conversation; quantities/Yen do not change. Do not collect optional ordinary sample drinks when checking these exact totals.

### Dungeon: mini-boss, before boss, after boss

1. Start fresh Slot 3 and follow [DUNGEONS.md](../docs/DUNGEONS.md)'s room route. Clear Room 1, open supply and key chests, spend key on Room 2 north door, activate A/B, obtain Ember Gauntlet, activate brazier, defeat lieutenant, open Boss Door.
2. Enter boss room and remain clear of Guardian contact. Save while NORMAL before defeating it. Record keys (normally zero after the one authored key is spent), inventory, current room, position/facing/health. Stop application, rerun, Load Slot 3.
3. Verify lieutenant absent on revisiting its room, Boss Door open, Guardian still alive, key count unchanged, three chests remain opened without reward duplication, switches/brazier active, room clears retained, Gauntlet still owned. Return to saved boss room/position and verify movement.
4. Defeat Guardian, wait for NORMAL, Save; stop application, rerun, Load. Guardian stays absent, dungeon completed, gates open. Exit/re-enter; terminal state and item remain. Automated tests additionally used a nonzero key count to verify key serialization, without changing authored game content.

### Shop stock and SOLD OUT

1. Start a fresh slot; do not collect other items/spend money. Enter Kagami Mart and buy exactly two Spirit Fragments at ¥500 each.
2. Leave shop UI; expected inventory fragments 2, Yen ¥2,000, stock 1. Save, stop application, rerun, Load, reopen shop: all three values match.
3. Buy final fragment: fragments 3, Yen ¥1,500, SOLD OUT. Save, restart/load, reopen shop: SOLD OUT persists. Attempt fourth purchase: all values unchanged. Unlimited drink/soda stock remains unlimited.

### Permanent overworld objects

1. In a fresh slot, interact with southwest chest (90,330): two healing drinks. Close dialogue; open door (145,330), activate switch (190,350), touch soda (95,380).
2. Save, stop application, rerun, Load. Chest remains open without additional drinks, door remains open/nonblocking, switch remains activated, soda pickup remains collected, inventory still has one soda. Use saved consumable while damaged to verify HealthComponent integration.
3. Travel out/back; flags remain. Ordinary unconfigured pickups/chests retain their original reset behavior; persistence is an explicit content choice.

### Invalid-file acceptance

Use a copy in an unused test slot. Malformed JSON must display Corrupted Save and fail Load without deleting the file or altering current runtime. A missing scene, newer save_version, missing profile, wrong top-level section type, or invalid cardinal facing must fail safely. Removing optional world_state/shop_stock/quests/etc. must load their defaults, never inherit another slot. An unknown item/quest ID should warn and skip; negative/overlarge quantities are clamped. Reopen menu after fixing the file to refresh metadata.

## Automated evidence and limitations

Headless validation used Godot **4.7.2 stable**. Separate application processes verified quest-ready/completed, dungeon pre/post-boss, all configured world samples, inventory/health/facing/location/Yen/stock, slot isolation, schema failures, menu keyboard/controller events, and safe-write failure paths. Unique enemy persistence was tested with a temporary fixture. Earlier Phase 1–8 validation suites and script-warning checks passed.

The session had no write grant for the actual Godot user-data save folder, so file-writing tests used an isolated copy with SAVE_DIRECTORY redirected to a writable temporary folder. Production remains `user://saves`. Real user-directory writes and graphical/physical-controller acceptance need the editor check above. Sandbox log/global-preference access and macOS certificate messages are environmental; malformed-definition and induced backup failures intentionally produce warning/error output in tests.

Manual saves only. No automatic slot loading at startup, autosave/checkpoint, cloud/platform integration, backup recovery UI, settings/control-binding saves, import/export, encryption/compression, final intro/title/Game Over screen, or controller name-entry keyboard. Main/DevTest remain original standalone sandboxes; New Game enters the WorldArea route. No navigation-safe relocation for changed maps; saved coordinates restore normally. Saving UI locks the player without pausing enemies/world time; damage cancels it. Authored definitions and IDs must remain compatible or receive explicit migration. Stop after Phase 9.

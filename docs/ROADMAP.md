# Development roadmap

## Source and scope

This roadmap records only the phases explicitly identified in the development requests. A full project design brief was not present in the repository or provided in this conversation. Later phase titles, ordering, and acceptance criteria remain awaiting that brief; no new major features or phase sequence are inferred.

## Phase 0 — Project Foundation (passed)

Foundation deliverables:

- Preserve the existing Godot 4.x project, GDScript choice, Git repository, and folder architecture.
- Configure a 384 × 216 pixel-art viewport with integer scaling, nearest filtering, and appropriate pixel snapping.
- Prepare named keyboard and basic gamepad input actions.
- Document the project, folder purposes, and phase boundaries.
- Provide `game/main/dev_test.tscn` with visible placeholder background, solid obstacles, and a stationary Player instance.
- Validate resource loading and project configuration with the available Godot executable.

Phase 0 excludes combat, enemies, inventory behavior, quests, dialogue, save/load, dungeon logic, health, and advanced player state machines.

## Phase 1 — Player Movement Prototype (passed)

The existing prototype is extended within its original architecture:

- Immediate eight-direction movement via `Input.get_vector()` and `move_and_slide()`.
- Exported starting speed of 90 pixels per second, consistent diagonal speed, and analog gamepad strength.
- Independent last-facing tracking; stronger axis wins, with vertical priority on equal diagonals.
- Four idle and four walk placeholder animations using the existing polygons, a facing marker, and discrete one-pixel bobbing.
- Editable feet collision rectangle and an unsmoothed camera with whole-pixel rendering positions.
- DevTest expanded with boundaries, a narrow gap, corners, and open space; movement is enabled on its Player instance.
- Phase 0 display settings and action bindings remain unchanged.

Movement, input bindings, animation selection, facing retention, collision, and camera behavior were validated and the milestone passed. Phase 1 included no combat or later gameplay systems. Its working behavior remains the basis for subsequent approved work.

## Phase 2 — Basic Combat (passed)

- Shared damage, health, hurtbox, and timed hitbox components.
- One cardinal starter-sword slash using existing facing and attack input.
- Player/enemy health, hurt feedback, wall-safe knockback, invulnerability, and death handling.
- Exactly one basic Slime enemy type with direct detection/chase and cooldown-based melee attacks.
- Two enemy instances in DevTest, preserving the existing movement/collision test area.
- Validate timing, damage deduplication, attack direction, collision masks, obstruction, invulnerability, deaths, and Phase 1 regression.

No advanced attacks, equipment, inventory, magic, skills, save/load, drops, health pickups, bosses, or advanced AI are implemented. Stop after this combat milestone.

## Phase 3 — World Interaction (passed)

- Shared Interactable contract and short facing-based nearest-object detector with deterministic ties and world obstruction checks.
- Player INTERACTING lock, named single-press input, control restoration, and damage/death cancellation integrated with existing states.
- Resource-driven sequential dialogue and one scene-local screen-fixed panel with input release/consumption guards.
- One static NPC with three lines, a reusable sign, unlocked/locked physical doors, a one-time opening chest, and nonblocking automatic pickups.
- Dedicated upper-right DevTest section preserves all Phase 1–2 test areas and both Slimes.
- Initially used temporary chest rewards and a pickup counter; Phase 5 replaces them with real items.
- Headless interaction validation and previous movement/combat regression suites pass. Manual controller/UI verification and milestone approval remain with the developer.

Stop after this interaction milestone. No quests, inventory, shops, keys, schedules, save/load, or scene transitions are implemented.

## Phase 4 — Scene Transitions and Room Flow (passed)

- Focused persistent fade manager, synchronous destination preflight, and runtime scene replacement.
- Reusable interaction-based scene doors and automatic Player-only zones; original physical doors remain unchanged.
- Unique named SpawnPoint markers, safe defaults, optional facing/override rules, pixel-aligned placement, and graceful failure handling.
- Per-area CameraBounds nodes; immediate unsmoothed follow within viewport-sized integer rectangles.
- Scene-owned Player recreation with health/max health, facing, and remaining invulnerability transfer; scoped input locks and hurt/death cancellation.
- Dedicated exterior, interior, and Room B route with safe arrival points, cooldown, and overlap/re-entry guards.
- Headless travel/failure/loop/camera/state checks and Phase 1–3 regressions pass. Manual rendering/controller acceptance remains with the developer.

Phase 4 added no inventory, save/world-state persistence, dungeon framework, streaming, or cinematic cameras. Its approved transition foundation is preserved in Phase 5.

## Phase 5 — Inventory and Item System (passed)

- Separate ItemData Resources, explicit item registry, runtime InventoryEntry/Inventory manager, and focused inventory UI.
- Three test items/icons: one healing consumable, one unique shrine charm, and stackable spirit fragments.
- Atomic capped stacking, safe additions/removals, unique-key protection, change signals, and health-based consumable effects.
- Real pickups/chest rewards replacing the temporary counter/fake reward logic; failure keeps rewards available and cancellation preserves combat states.
- Event-driven inventory display with categories, empty states, built-in keyboard/controller focus, consumable use, and existing scoped Player locks.
- Inventory persists through Phase 4 travel and resets on game restart. DevTest and exterior samples support manual collection/healing/persistence routes.
- Headless item/inventory/UI/reward/state/transition checks and earlier-phase regressions pass. Native inventory screen/keyboard/full-health feedback inspected; physical controller and display acceptance remain manual.

Phase 5 added no save persistence, shops, Yen, equipment, quests, dungeon keys, crafting, sorting, discarding, or quick-use UI. Its approved systems are extended in Phase 6.

## Phase 6 — Reusable Dungeon Foundation (passed)

- Focused DungeonManager Autoload and per-ID runtime DungeonState; no disk save persistence.
- Separate configured WorldArea rooms using existing scene transitions, named spawns, scoped Player locks, and camera bounds.
- Dungeon-only small keys, atomic persistent key doors, a mini-boss-gated Boss Door, and event-driven switch/room-clear barriers.
- Interaction switches with one/all configured conditions; an item-gated Ancient Brazier.
- Registered HealthComponent death signals, permanent room clears, and removal of cleared required enemies on room reconstruction.
- Existing TreasureChest extension for persistent inventory, Small Key, and unique dungeon-item rewards.
- Ember Gauntlet item definition, protected DUNGEON_ITEM category, and existing inventory display integration.
- Configured stronger Slime lieutenant/Guardian prototypes, encounter locks, boss completion feedback, and named overworld return/re-entry.
- Development-only dungeon reset method and optional debug display; focused architecture/manual route documentation.
- Headless full-route, persistence, collision, reward/cancellation, script-warning, and Phase 1–5 regression checks pass. Graphical and physical-controller acceptance remain manual.

DevDungeon validates infrastructure only. No final Temple of Embers, story rewards, maps, Boss Keys, music, checkpoints, Game Over system, advanced puzzles/AI, disk saves, or quests. Stop pending milestone approval.

## Phase 7 — Reusable Quest System (passed)

- Static QuestData/objective/reward resources and separate QuestRuntime state.
- Five event-driven objective types, clamped progress, existing inventory initialization, and stable NPC/enemy/location/object IDs.
- Simple completed-quest prerequisites; AVAILABLE remains distinct from ACTIVE.
- Reusable NPC offer component, minimal Yes/No choices, reminder/turn-in/post-completion dialogue.
- Atomic quest-item hand-in and item rewards; optional health restoration/story-only rewards.
- Active/Completed journal with named keyboard/controller input and existing scoped player locks.
- Complete A Small Favor side quest, gated Old Lucky Charm, two drinks, and data-only prerequisite follow-up.
- Session persistence through house/dungeon travel; documentation and regression checks.

No disk saves, Yen, shops, skill/cosmetic rewards, markers, relationship systems, timers, procedural quests, or advanced branching. Stop pending milestone approval.

## Phase 8 — Yen and Shop System (passed)

- Configurable session Yen wallet, currency signals, shared formatter, and simple HUD.
- Item default prices, reusable ShopData/ShopEntryData, independent runtime stock.
- Atomic single-item purchasing through existing inventory with funds/stock/capacity validation and rollback.
- Buy/Leave merchant choices, keyboard/controller shop screen, existing player-lock/cancellation architecture.
- Kagami Mart placeholder interior linked to the existing exterior through SceneTransitions.
- Small Healing Drink ¥300 unlimited, Spirit Fragment ¥500 stock three, Energy Soda ¥250 unlimited with one-HP healing.
- A Small Favor retains its original two drinks and gains ¥500, with duplicate/capacity safeguards.
- Session persistence, documentation, and prior-phase regression validation.

Prices/starting Yen are temporary. No selling, dynamic economy, equipment/cosmetic shops, crafting, or disk saves. Stop pending milestone approval.

## Phase 9 — Save / Load Foundation (implemented; awaiting editor acceptance)

- Three independent manual save slots with JSON version 1, metadata, active slot, safe replacement, and a previous valid backup.
- Central chosen name/playtime and player scene, rounded position, cardinal facing, and HealthComponent data.
- Existing inventory, wallet, quest, dungeon, and shop managers expose focused snapshot/load/reset APIs; authored resources remain unchanged.
- Explicit stable-ID world persistence for overworld chests, permanent doors/switches, one-time pickups, and unique enemies; dungeon state stays in DungeonManager.
- New Game name/slot selection, clean resets, safe loading, keyboard/controller focus, and delete/overwrite confirmation.
- Required-field/version/location preflight, missing-field defaults, invalid legacy IDs/quantities, corruption errors, and migration hook.
- Separate-process quest/dungeon/world/economy saves, cross-slot isolation, failed-write safeguards, save UI, and earlier phase regressions validated headlessly.
- Save format and exact manual acceptance routes documented in `documentation/SAVE_FORMAT.md`.

Implementation is complete. Real user-data directory writes, display layout, and physical-controller behavior remain editor acceptance checks. No autosave/checkpoints, cloud/platform integration, encryption, New Game+, settings syncing, or additional features are included. Stop after Phase 9.

## Visual direction foundation (implemented; awaiting approval)

- `docs/ART_DIRECTION.md` is the visual bible. It sets the 640 × 360 internal resolution (to match the Sakura City mockup's framing at integer zoom 1.0), 16 × 16 tiles, 32 × 32 chibi frames, and the painted-night palette with additive glow lighting. It also covers the HUD, animation and import rules.
- **Original art matching the mockup:**
  - protagonist and nine NPC sheets
  - a 71-tile city tileset
  - 37 prop scenes: station, shrine, shops, canal, train, lamps, poles
  - stepped glow textures
  - HUD art, a proportional pixel font, and preview item icons
- **Engine and code changes:**
  - Player re-anchored to its feet for y-sorting.
  - `CameraProfile` / `GameCamera` added.
  - `CameraBounds` centres undersized rooms.
  - Legacy menus and the dialogue panel re-anchored for 640 × 360.
  - `GameHUD` (hearts, orbs, Yen, quick slots, minimap) and the `AmbientNPC` crowd scene added.
- `visual_test_district.tscn` (Sakura City) validates scale, framing, density, HUD, lighting and pixel clarity.

Protagonist locked to the character reference sheet: an 8-direction idle/walk/run sprite sheet, and hold-sprint running with `run_speed`.

Display settings changed (resolution, window size, clear colour). There are no new gameplay systems; quick slots and magic are display-only.

## Next milestone — first polished vertical slice (not started)

The next explicitly identified milestone combines the approved existing systems into a small real section of the opening. Its content/scope requires a separate user request; no additional isolated framework phase is introduced here.

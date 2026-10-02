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

## Phase 6 — Reusable Dungeon Foundation (implemented; awaiting acceptance)

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

## Phase 7 — Reusable Quest System (not started)

The supplied Phase 6 request identifies quest objectives/rewards, quest journal, prerequisites, and the first complete side quest as Phase 7. No quest implementation is included in Phase 6.

## Later phases

Await the full project design brief before assigning further phase ordering or feature schedules.

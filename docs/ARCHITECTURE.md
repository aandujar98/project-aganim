# Project architecture

This document describes the existing folder structure. Phase 0 preserves it; no alternative architecture is introduced.

## Root

- `project.godot`: engine settings, named input actions, and startup scene.
- `icon.svg`: current application icon.
- `.gitignore`: excludes the generated `.godot/` cache, Android build directory, and `.DS_Store`.
- `README.md`: project introduction and development instructions.

## Game content

Scenes (`.tscn`), feature-specific GDScript (`.gd`), and resource definitions (`.tres`) belong together where practical.

- `game/main/`: application entry scene and development test scenes. `main.tscn` remains the startup scene; `dev_test.tscn` is the movement/collision/combat/interaction sandbox; its small `dev_test.gd` wires the scene-local dialogue UI, optional health/state/prompt labels, and the inventory-input hint. Real quantities belong to Inventory.
- `game/player/`: reusable Player scene and its script. The reusable CharacterBody2D retains separate polygon visuals, an adjustable feet collision rectangle, and a following Camera2D. AnimationPlayer holds four idle and four walk placeholders; a marker indicates facing. The small typed script reads named movement actions, updates facing, calls `move_and_slide()`, selects animations, and rounds the camera position. The development scene now uses the script without the Phase 0 `null` override.
- `game/npcs/`: the reusable static NPC scene/script and three-line test dialogue resource.
- `game/enemies/`: reusable enemy scenes and scripts. `slime.tscn` / `slime.gd` is the single basic enemy type in Phase 2.
- `game/items/`: ItemData, the item registry, inventory entries/manager, reusable real-item pickups, and category-organized definitions under `data/`.
- `game/quests/`: future quest definitions and related code.
- `game/world/districts/`: outdoor areas, including the existing placeholder test district.
- `game/world/interiors/`: indoor locations.
- `game/world/shared/`: reusable world objects, including the sign, physical door, and treasure chest with their message resources.
- `game/dungeons/`: future dungeon scenes and rooms.
- `game/ui/hud/`: in-game HUD scenes.
- `game/ui/menus/`: menus and shared menu screens.
- `game/ui/inventory/`: persistent inventory CanvasLayer screen, built-in focused controls, and item-acquired notification.
- `game/ui/dialogue/`: the reusable CanvasLayer dialogue UI and focused scene-local DialogueManager script.

These folders reserve places for future work; they do not imply implemented systems.

## Shared scripts and resources

- `scripts/shared/`: GDScript reused across multiple features.
- `scripts/save/`: future save code and schema definitions. Actual player saves belong in `user://`, outside the repository; Phase 0 adds no save/load behavior.
- `resources/themes/`: shared Godot UI themes.
- `resources/shared/`: resources used by multiple features.

## Art and audio

- `art/characters/`, `art/enemies/`, `art/items/`: shared character, enemy, and item art.
- `art/environments/`, `art/tilesets/`: environment art and tile textures.
- `art/effects/`, `art/ui/`: visual effects and UI art.
- `audio/music/`, `audio/ambience/`, `audio/sfx/`: music, environmental audio, and sound effects.

Current scenes use built-in placeholder polygons and three small placeholder item SVGs; no external art or dependencies are required.

## Documentation and conventions

- `docs/`: design and development documentation. Its existing `.gdignore` keeps documentation out of Godot's resource import scan.
- Use lowercase `snake_case` for game filenames and folders, typed GDScript where useful, and named input actions.
- Preserve `.gd.uid` and asset `.import` files; exclude the generated `.godot/` directory.
- The pixel-art baseline is 384 × 216 with nearest filtering, viewport integer scaling, and aspect preservation. Rendered 2D transforms snap to pixels; physics coordinates remain continuous. Vertex snapping is left disabled to avoid combining both snapping modes.
- The default window is 3× the internal resolution. Other aspect ratios may have black bars; intermediate window sizes retain an integer scale.

## Phase 2 combat foundation

The existing Player keeps its movement, facing rules, polygon animations, feet collision, and camera. It adds HealthComponent, HurtboxComponent, and SwordHitbox children. A small enum handles NORMAL, ATTACKING, HURT, and DEAD; it is not a general state-pattern framework.

Shared GDScript in `scripts/shared/`:

- `damage_data.gd`: a lightweight RefCounted hit record containing amount, source actor/position, direction away from the source, and knockback force.
- `health_component.gd`: maximum/current health, validated damage, healing capped at maximum, typed health/damage signals, and a single death signal. Healing cannot revive dead actors.
- `hurtbox_component.gd`: receives hits, checks health and an enabled flag, guards against self-hits, enforces configurable invulnerability, forwards damage to HealthComponent, and emits hit data to its actor.
- `hitbox_component.gd`: holds damage/knockback values and a timed active window. Each active physics tick queries the current collision shape transform against the configured hurtbox mask, preventing stale overlaps after a turn. An accepted target can be hit only once per swing. A World-only ray check prevents damage through walls. Hitboxes do not monitor other areas automatically and cannot be detected by other hitboxes; their visuals and damage queries are inactive outside the window.

Actors respond to accepted hits with a hurt state and knockback, without editing one another's health. Knockback uses `velocity` / `move_and_slide()` and decays to zero across the 0.18-second hurt period; it never directly changes physics position.

### Player and starter sword

- Player health: 6; sword damage: 1.
- Stored Phase 1 cardinal facing determines the slash. Equal movement diagonals retain the existing vertical-priority rule.
- One new press starts one swing; held attack does not auto-repeat. Movement/facing lock for 0.25 seconds. The hitbox is active immediately for the first 0.10 seconds, capped by total attack duration.
- The slash rectangle is 28 × 22 pixels, centered 24 pixels in front of the feet origin and rotated to the cardinal direction. A yellow placeholder shows its range; idle/walk animations resume afterward.
- Sword knockback starts at 110 pixels/second; the enemy's decaying hurt movement lasts 0.18 seconds.
- Player post-hit invulnerability: 0.75 seconds. Red tint marks hurt; simple alpha flashing marks the remaining protected period.
- Damage interrupts a swing; death disables sword/hurt interactions and control, dims the player, and prints a restart instruction. Stop and rerun DevTest to restart; there is no respawn/save/Game Over system.

### One basic enemy

`slime.tscn` uses CharacterBody2D, feet collision, placeholder polygon visuals, shared HealthComponent/HurtboxComponent, an AttackHitbox, and an Area2D detection circle. Its simple enum handles idle, chasing, attacking, hurt, and dead.

- Health: 3; contact attack damage: 1; attack knockback: 90 pixels/second.
- Detection radius: 120 pixels; movement speed: 35 pixels/second.
- Chase the player group directly; leaving range or player death returns the enemy to idle. No pathfinding is used.
- Within 24 pixels, stop and start a 0.25-second melee attack with a 0.10-second active window and 1-second cooldown measured from attack start.
- Invulnerability after a hit: 0.25 seconds; hurt/recoil: 0.18 seconds.
- Death disables movement, body collision, and combat immediately, dims visuals, then safely queues removal after 0.25 seconds.

### Collision layers and masks

- Layer 1, World (bit 1): static obstacles. DevTest World bodies allow Player and Enemy collision (mask 6).
- Layer 2, Player (bit 2): body mask 5, colliding with World and Enemy.
- Layer 3, Enemy (bit 4): body mask 7, colliding with World, Player, and Enemy.
- Layer 4, PlayerHitbox (bit 8): mask 64, targeting EnemyHurtbox only.
- Layer 5, EnemyHitbox (bit 16): mask 32, targeting PlayerHurtbox only.
- Layer 6, PlayerHurtbox (bit 32): mask 0; receives queries but does not monitor.
- Layer 7, EnemyHurtbox (bit 64): mask 0; receives queries but does not monitor.

Friendly fire is excluded through these masks and the self-hit guard. No hitbox-to-hitbox damage is used. Phase 0 display and input configuration stays unchanged; only these collision-layer names are added to `project.godot`.


## Phase 3 world interaction foundation

No original folder was moved. Shared interaction/data scripts remain in `scripts/shared/`; objects live in the existing feature folders. Player retains its existing scene children and adds only `InteractionDetector` after the combat components. No global manager or event bus is added.

### Contract and selection

`Interactable` extends Area2D and exposes `interact(actor, manager)`, `interaction_text`, `enabled`, and local `interaction_started` / `interaction_finished` signals. It owns begin/finish/cancel helpers. Player calls this single contract and does not know whether the object is an NPC, sign, door, or chest. Solid objects contain a World-layer StaticBody2D child separate from their interaction area.

`InteractionDetector` queries a rectangle directly through PhysicsDirectSpaceState2D at the current transform, like the existing sword query. Its origin is the Player's feet at `(0, 10)`; exported default reach is 30 pixels and width is 20 pixels. The rectangle extends forward along the stored cardinal facing. Interactable area edges may overlap the rectangle; object centers behind its origin are rejected. This avoids stale Area2D overlaps after turning. It considers layer 8 (bit 128), areas only, selects the closest enabled object's center, and breaks equal-distance ties by scene path. One press invokes one selected object. A World-only ray rejects obstacles; a target's own solid body and coincident enabled target endpoints are allowed. The query is capped at 64 nearby areas, well above this small test scene's count.

Layer 8 is named `Interactable` in project.godot; its areas have mask 0 and monitoring disabled. World solids remain layer 1/mask 6. Pickups use layer 0/mask 2 and monitor Player bodies only, with no physical body. Existing combat masks and display/input settings are preserved.

The optional input-neutral prompt is a DevTest CanvasLayer label driven by `target_changed`; disabling `show_combat_debug` hides all temporary debug labels. There are no permanent visible interaction rectangles.

### Player lock and interruptions

`INTERACTING` is appended to the small PlayerState enum, preserving NORMAL/ATTACKING/HURT/DEAD values. Interact input uses `_unhandled_input` and the named action, rejects keyboard echo, and is accepted only in NORMAL. `begin_interaction(owner)` grants one owner a lock, stops movement, and selects idle. INTERACTING stops movement and prevents attack input. `end_interaction(owner)` releases only the matching owner and restores NORMAL only if still INTERACTING.

Accepted damage/death sets HURT/DEAD first, clears the owner, and emits `interaction_cancelled(owner)`. Objects close their message or cancel their pending animation. A late finish callback cannot overwrite hurt/death. A cancelled opening chest resets its lid and grants no reward; it can be retried after recovery. If a reward was already shown, the chest remains open without duplicating it. Actors are not invulnerable while talking. If an owning object is removed, its cleanup releases/cancels the lock; Player also recovers if its owner becomes invalid.

### Dialogue data and UI

`DialogueLine` and `DialogueData` are Resources with exported speaker/text and a typed line array. The four supplied `.tres` assets hold NPC, sign, locked-door, and chest-message content. DialogueManager contains no story strings.

`game/ui/dialogue/dialogue_ui.tscn` is a scene-local CanvasLayer (layer 10), containing Panel → SpeakerLabel, DialogueLabel, ContinueIndicator. The panel occupies `(8, 136)` to `(376, 208)` in the fixed 384 × 216 viewport, with small readable labels, wrapping text, an opaque fill, and a one-pixel border. It remains independent of Camera2D and inherits existing integer scaling. Empty speakers hide the name label. There are no portraits, typewriter, branches, or advanced story scripting.

The manager starts resource data, displays sequential whole lines, advances on Interact, closes after the last line, and calls the owner's finish callback. Local `dialogue_started` / `dialogue_finished` signals expose lifecycle. The opening input is consumed by Player; the manager requires release before accepting another press and consumes active dialogue events. Keyboard echoes cannot advance. Closing input is consumed, so it cannot reopen an object with the same event.

DevTest assigns its DialogueUI to `Player/InteractionDetector.dialogue_manager`. Reuse that wiring in a later scene when approved; no Autoload or scene transition framework is required here.

### Reusable objects and temporary state

- NPC: static polygon person with a solid body, exported DialogueData, and three sequential Resident lines. No AI, schedules, or facing animation.
- Sign: solid placeholder board with an exported message resource; shares the dialogue contract and lock.
- Door: exported `locked` flag. Unlocked interaction hides the leaf, disables solid collision, disables further interaction, emits `opened`, and immediately returns control. Locked interaction shows `It's locked.` and preserves collision. Doors stay open only during the running scene; no keys or transitions.
- Chest: retains the 0.45-second lid tween and scoped interaction lock. Phase 5 replaces the fake message-only reward with exported `reward_item_id` / `reward_amount`, inventory acceptance, and a generated shared-dialogue reward line. Invalid or rejected rewards keep it closed. Completion emits `opened(reward_item_id)` once and the chest remains open in that scene instance.
- Pickup: automatic NORMAL Player-body collection, real `item_id` / `amount` fields, inventory acceptance before disappearance, local `collected` signal, deferred monitoring disable, and safe queued removal. Sprite icons replace the temporary yellow diamonds; a magenta fallback marks missing item/icon data. Failed additions stay in the world and can be retried by leaving/re-entering.

Phase 3 originally used message-only rewards and a pickup counter. Phase 5 replaces those paths with inventory items, while preserving interaction behavior. Currency and save/world persistence remain absent; the old message resource is preserved but unused.

### DevTest layout and verification

All existing movement obstacles, boundary walls, central narrow gap, corner, and both Slimes remain. A blue-gray section in the upper-right contains NPC `(480, 75)`, sign `(560, 75)`, unlocked door `(660, 75)`, locked door `(720, 75)`, chest `(660, 185)`, and three pickups along y=185. The original Player spawn and camera limits remain unchanged.

Headless validation with Godot 4.7.2 checks facing/range/obstruction, nearest/tied target selection, one-per-press keyboard/gamepad events, dialogue sequencing/locking/close, camera-independent UI, both door states/collision, one-time chest reward and interruption/retry, collection counts, attack/hurt/death rejection, and interruption safety. Existing Phase 1 movement and Phase 2 combat regression suites also pass. Check physical controller mappings and readable integer-scaled UI in the editor before marking the visual milestone accepted.


## Phase 4 scene transitions and room flow

Original folders, Main, district, DevTest, combat components, and physical Phase 3 doors remain intact. New reusable scene helpers live in `game/world/shared/`; the focused manager lives in `game/main/`. The test exterior and Room B are under `game/world/districts/transition_test/`; the house is under `game/world/interiors/transition_test/`. Phase 4 added no general world manager or loading screen. Phase 5 adds inventory state separately.

### Area and spawn contract

A transition destination has a `WorldArea` Node2D root, exactly one Player in the existing player group, a `CameraBounds` node, and descendant `SpawnPoint` Marker2D nodes. DialogueUI is scene-local as in Phase 3. WorldArea wires that UI to the Player detector, places a safe default on direct F6 launch, applies camera limits, and manages only a temporary test status label.

Spawn IDs use lowercase snake_case names describing arrival context: `default`, `house_front`, `house_inside`, `from_east`, `from_west`. IDs must be unique within an area. An unknown requested ID produces a developer warning and resolves to `default_spawn_id` (normally `default`). If no default exists, or IDs are duplicated, transition validation fails and preserves the source scene. There is no fallback to arbitrary `(0, 0)`.

Spawn markers expose optional facing direction. Entrance override takes priority; otherwise an enabled spawn direction wins; otherwise the previous Player facing is retained. Directions are reduced to the same cardinal convention as Player movement. WorldArea rounds destination coordinates and camera position to whole pixels. Place markers spatially clear of bodies/entrance zones; there is no automatic collision-free spawn search.

### Transition objects

`SceneEntrance` extends the existing Interactable contract. Exported destination `.tscn` path, destination spawn ID, INTERACTION/AUTOMATIC activation mode, and optional facing override are configured on each object. Player contains no scene paths or scene-loading logic.

INTERACTION uses the existing detector's short range, facing, nearest-target rule, wall check, and named interact action. `SceneDoor` is a small separate subtype reusing the physical door scene's polygons/body and locked-message resource. It always requires interaction. Locked scene doors show the shared message and remain solid; unlocked scene doors request a scene change. Original `door.gd` behavior remains entirely unchanged: its physical doors still open in place. No keys are implemented.

AUTOMATIC uses a Player-body-only Area2D and polls its current overlaps. Enemies cannot activate it. A normal entering Player starts travel; attack/hurt occupants wait until NORMAL. Dead actors leave the Player group. A zone entered during busy/cooldown latches until the Player exits, so even an accidental destination overlap cannot bounce back. Failed automatic configuration is attempted once per occupancy, avoiding warning spam.

### Manager and fade flow

`SceneTransitions` is the sole new Autoload, instancing `game/main/scene_transition_manager.tscn`. CanvasLayer 100 and a full-viewport black ColorRect place the fade above world and DialogueUI (layer 10).

1. Check one living, NORMAL Player belongs to the active source; reject busy/cooldown/interaction/attack/hurt/death requests.
2. Synchronously load and instantiate the destination off-tree. Validate its WorldArea, one Player, default/requested spawn, and viewport-sized camera bounds before fading or destroying anything. Missing/invalid resources emit a developer warning and failure signal.
3. Acquire Player's transition lock and defer scene mutation out of the physics callback. Emit `transition_started` and log source/destination/requested/resolved spawn once.
4. Fade out (exported default 0.25 seconds). Damage/death during this interval cancels the replacement and fades back to the source.
5. Capture the source Player runtime data, disconnect its cancellation signal, detach the old scene before adding the new scene, and queue the old scene for deletion. There are never two Players active in the SceneTree.
6. Apply runtime data to the recreated Player, acquire its lock immediately, place it at the resolved marker, set facing/idle animation, apply camera limits, and wait one physics frame under black for registration.
7. Fade in (exported default 0.25 seconds), release the lock without overriding hurt/death, and apply an exported 0.25-second arrival cooldown. Emit completion; interruption after arrival keeps the loaded scene and reports failure rather than reviving or replacing the actor.

The manager handles only runtime travel/fade/placement. Loading is synchronous; no async streaming, save system, cinematics, maps, quests, or global event bus are added. Signals are focused on transition start/finish/failure.

### Player recreation and locks

Scene-owned Player recreation fits the established scene architecture. `capture_runtime_state` / `apply_runtime_state` transfer current and maximum health, facing, and remaining hurtbox invulnerability. Idle/velocity reset at the destination. These small actor methods do not load scenes.

Transition begins through the existing INTERACTING owner lock; no enum was renumbered or new state machine introduced. A separate owner-scoped transition flag blocks normal input/detection throughout both fades, including normal recovery after a cancelled hurt event. Hurt knockback and death remain authoritative; their existing cancellation signal informs the manager. `end_transition` releases only its owner and never restores NORMAL over HURT/DEAD. Outgoing damage cancels travel; incoming damage/death keeps the destination and preserves its actor state. Actors are not made invulnerable by travel.

### Camera bounds

CameraBounds is a reusable axis-aligned Node2D exposing a Rect2i. Its global origin plus integer rectangle defines Camera2D limits. It requires at least the internal 384 × 216 viewport size, disables position/limit smoothing, resets and forces camera scroll, and preserves Player's pixel-aligned follow logic. Keep area/bounds roots unscaled/unrotated. No pans, shake, zoom, or boss behavior.

Test sizes: exterior 768 × 432; house interior 384 × 216; Room B 512 × 288. Per-area limits replace scene-specific Player overrides only in these new scenes. Old DevTest/district overrides are preserved.

### Validation and current limits

Headless route and edge-case checks cover both entrance modes, fade locks/alpha/layering, facing/range, all named returns, maximum/current health transfer, camera centers/limits, no duplicate Players, repeated trips, missing destinations/spawns/defaults/bounds, duplicate Players, keep-facing/override priority, pixel rounding, accidental arrival overlap, exit/re-entry rearming, enemies, attack/hurt waiting, and outgoing/incoming death cancellation. Existing Phase 1–3 movement/combat/dialogue/object regression suites pass. Enabled GDScript warnings are also checked as errors in memory, without changing project settings.

Phase 4 itself adds no disk save or dungeon persistence. Ordinary scene-local enemies, doors, chests, and pickups may reset when reloaded; Phase 6 dungeon objects use the dedicated runtime state described below. Basic Player runtime data travels through the manager; Phase 5 inventory persists independently in its Autoload. New transition areas reuse Phase 3 signs/UI; DevTest remains an independent test scene. Every future transition destination must adopt WorldArea and provide a safe default, one Player, and valid bounds. Reopen/reload an already-running editor once after adding the Autoload; verify it appears enabled in Project Settings → Globals → Autoload. Display and input settings need no change.


## Phase 5 — Inventory and Item System

### Item definitions and lookup

`game/items/item_data.gd` defines a Resource with stable snake_case `id`, display name, multiline description, Texture2D icon, category (CONSUMABLE / KEY_ITEM / MATERIAL / COLLECTIBLE), stackable flag, max stack, use-effect ID, and effect value. Definitions contain no owned quantities. `quantity_limit()` enforces one for nonstackable/key items and max_stack otherwise. IDs remain unchanged when visible names change.

Three `.tres` definitions live under `game/items/data/consumables/`, `key_items/`, and `materials/`; their placeholder 16 × 16 SVGs live in `art/items/`. Small Healing Drink (`small_healing_drink`) heals one, Mysterious Shrine Charm (`shrine_charm`) is unique/non-consumable, and Spirit Fragment (`spirit_fragment`) is stackable with no use effect.

The `ItemDatabase` Autoload loads a small explicit resource list once at runtime, after asset import, and indexes by ID. Invalid definitions/duplicate IDs are warned and excluded. `get_item(id)` returns null with a useful warning for unknown IDs. No filesystem scan or per-frame registry work is used. Register a later approved item by adding its resource path to this single list.

### Inventory state and API

The `Inventory` Autoload owns a dictionary of InventoryEntry RefCounted values (`item_id`, `quantity`). The API is `add_item(id, amount = 1)`, `can_add_item(id, amount = 1)`, `remove_item(id, amount = 1)`, `has_item(id, amount = 1)`, `get_quantity(id)`, `get_entries()`, and `use_item(id, actor)`. Mutations return success/failure. UI receives quantity snapshots from `get_entries()` so callers cannot modify owned entries by reference.

Distinct item IDs have no slot-capacity limit. One entry per ID stacks up to its definition's limit (99 for the test drink/fragment). Additions are atomic: overflow rejects the entire amount without partial collection. Nonpositive amounts and excessive removals fail; zero quantity removes the entry. Nonstackable items and keys accept one copy, reject subsequent copies, and stay at one. Key-item removal and use are rejected; there is no discard/drop UI for any category.

Signals are `inventory_changed`, `item_added(id, amount)`, `item_removed(id, amount)`, and `item_used(id)`. A small mutation guard protects transactions against reentrant signal callbacks. The manager contains no UI node paths/layout or Player ownership. The inventory survives scene-owned Player recreation and resets only when the running game restarts; there is no serialization.

### Consumable effects and health

`ItemEffectHandler` is a small shared RefCounted helper. It validates a living Player, allowed state, and no active transition, then dispatches `heal_player` to the existing HealthComponent. Future approved effects can add a branch in this helper without item-specific logic in Player/UI. Unknown effects fail safely. The Player script and state enum are unchanged.

`HealthComponent.heal(amount)` now returns the actual restored amount, clamps to missing health, rejects nonpositive amounts, and never revives. Inventory consumes one only after successful healing. Full health preserves quantity and provides `Health is already full.` through `last_use_message`; UI displays the manager's result without implementing effects.

### World rewards

Pickup resolves its icon through ItemDatabase and adds its configured amount through Inventory on a valid Player overlap. It sets its collected guard, emits, hides, and frees only after success. Non-player/locked/invalid-state overlaps do not collect; leave and re-enter after recovery to retry. Failed IDs/full stacks/duplicate unique rewards remain available in the world.

Chest validates the definition and capacity before locking/animating. On completion it rechecks the actual addition; failure resets the lid and lock with a developer warning. Success marks it open, disables further interaction, emits once, and uses a generated DialogueData line with the real item name/amount. Damage before granting cancels without reward and allows retry; cancellation from reward signals does not grant twice or start late dialogue over hurt/death. Existing unlocked/locked physical doors and scene doors are unchanged. The prior static chest-message resource remains on disk but is no longer used.

DevTest preserves all original walls, movement paths, Slimes, NPC/sign/door tests. Its three pickups now give two drinks and one fragment; FragmentChest gives three fragments and the original Chest gives one charm. The fake collection counter is removed. TestExterior additionally has three nonblocking samples beside default spawn (two drinks, three fragments, one charm), allowing persistence testing along the existing house/region route without restarting.

### UI, input, and player locks

`InventoryScreen` is a persistent CanvasLayer (20), above dialogue (10) and below fades (100). A 384 × 216 screen contains Panel → CategoryTabs, ItemList, selected icon/name/category/quantity/description, Use/Close buttons, help, and feedback. ItemList displays icon, quantity first, and name; long names may ellipsize while selected details/tooltip show the full name. All/Consumables/Key Items/Materials tabs filter the event-driven list; Materials includes collectibles. Empty data/categories have explicit text and safe selection.

Opening selects the first available item and takes `Player.begin_interaction(self)` using the existing INTERACTING owner lock. Movement, sword, world interaction, and scene travel are blocked. Opening is refused during dialogue/chests, attack, hurt, death, transitions, or without a current-scene Player. Closing calls owner-matched `end_interaction`; damage/death cancellation and Player removal close the screen safely. The game is not paused; enemies continue to simulate.

Input uses named `inventory` and built-in `ui_*` actions. Existing I / Back bindings remain; ui_accept adds south/A alongside Enter/keypad Enter/Space, and ui_cancel adds east/B alongside Escape. Arrows/D-pad/left stick navigate built-in Control focus and ItemList; Tab/Shift+Tab cycle focus, left/right on focused tabs changes category, and confirm uses a selected consumable or focused button. Keys/materials have no Use action. No custom navigation state machine exists.

Inventory UI refreshes on opening, inventory events, category/selection changes; no per-frame rebuild/polling is used. Successful pickups show a two-second lightweight notification; chests use the existing dialogue message instead. Filtering and nearest rendering remain pixel-friendly. Native empty/populated screens, keyboard selection, full-health feedback, and key-item details were inspected; physical controller behavior should still be checked on the developer's device.

### Limits

Phase 5 itself added no save/world/chest persistence, shops, Yen, equipment, quests, dungeon keys, sorting, dropping/discarding, crafting, or quick-use UI. Ordinary local objects may still reset independently of session inventory. An already-owned unique overworld reward remains rejected (pickup retained or chest closed). Phase 6 extends this foundation with dedicated runtime dungeon chest/key state and a unique traversal item, described below.


## Phase 6 dungeon foundation

`game/dungeons/shared/` contains focused reusable dungeon state, manager, room-clear controller, persistent key/Boss doors, event-driven barriers, interaction switches, item-gated Ancient Brazier configuration, chest reward integration, and development display. `game/dungeons/dev_dungeon/` contains eight configured WorldArea room scenes and two stronger Slime scene variants. There is no alternate scene loader, dungeon camera, or dungeon logic in Player.

WorldArea has an optional exported stable `dungeon_id`. Its `_ready()` identifies the active dungeon; an empty ID clears active context while retaining stored states. Off-tree Phase 4 destination preflight cannot change active context. SceneTransitions still owns validation, fades, Player health/facing transfer, scoped locks, and camera placement. No transition-manager code changed.

DungeonManager stores one DungeonState per stable ID and emits relevant changes. Objects query state on load and respond to events, without per-frame puzzle polling. Required enemies are children of a designated Enemies container and use their existing HealthComponent.died signals. Once cleared, that container's enemies are removed on subsequent room loads.

TreasureChest exposes four small reward hooks so DungeonChest can reuse the exact opening animation, interruption safety, Player lock, and shared dialogue. DungeonChest records an explicit chest ID and supports inventory, dungeon Small Key, and dungeon-item rewards. Small keys belong exclusively to DungeonState. The new DUNGEON_ITEM ItemData category is unique, protected from removal/consumption, and shown by the existing inventory Key Items filter. Ember Gauntlet data lives in `game/items/data/dungeon_items/`; its placeholder icon remains under `art/items/`.

Dungeon progress exists only in memory for the current session. No disk persistence, overworld quest state, checkpoint system, or story completion rewards are added. See [DUNGEONS.md](DUNGEONS.md) for IDs, reconstruction, the test route, reset behavior, and extension guidance.

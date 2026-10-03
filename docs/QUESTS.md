# Reusable quests — Phase 7

## Definitions and runtime

`QuestData` exports a stable ID, title, description, typed objectives/rewards, prerequisite IDs, auto-completion flag, optional turn-in NPC ID, turn-in description, and ready message. `QuestObjectiveData` exports type, stable target ID, positive required amount, description, and optional consume-on-turn-in flag (COLLECT_ITEM only). `QuestRewardData` supports ITEM (existing item ID/quantity), HEALTH_RESTORE (positive amount), and NOTHING. Phase 8 appends YEN with a positive amount, delegated to Wallet; existing reward enum values are preserved.

Definitions live in `game/quests/data/`. The explicit QuestDatabase resource list loads once; it rejects invalid/duplicate definitions and missing item references. Empty IDs/targets and nonpositive quantities are rejected. Missing or cyclic prerequisites warn and remain unavailable. NPC/enemy/object/location IDs are configured stable strings, not scene names or display titles; their existence is verified by content configuration/testing rather than scanning every world scene.

QuestRuntime is separate RefCounted state with quest ID, enum state, typed objective progress, and objectives_complete. UI queries receive snapshots with copied progress. Resources are treated as immutable during play, not physically frozen against arbitrary developer script changes.

States: UNAVAILABLE → AVAILABLE when all prerequisites are COMPLETED; AVAILABLE → ACTIVE on acceptance; ACTIVE → COMPLETED only after all objectives and successful rewards, or ACTIVE → FAILED through the structural failure API. COMPLETED/FAILED are terminal. Unknown IDs query as UNAVAILABLE and cannot be accepted. A ready turn-in quest remains ACTIVE. There are no authored failure conditions, retry/reset API, or timers.

## Manager and events

QuestManager loads/registers definitions, owns runtime state, and emits quest_state_changed, objective_updated, and notification_requested. Main APIs: register_quest, get_definition, get_runtime, get_state, make_available, accept_quest, record_event, is_active, is_completed, is_ready_to_turn_in, complete_quest, turn_in_quest, and fail_quest. `complete_quest` rejects turn-in quests; `turn_in_quest` checks the configured NPC ID and living player's state. The NPC configuration supplies that ID; this is a gameplay contract, not an authorization/security boundary.

- COLLECT_ITEM: Inventory.item_added supplies ID/amount. Acceptance initializes progress from currently owned quantity. Subsequent additions accumulate; removal never reduces progress. Clamp at the requirement.
- DEFEAT_ENEMY: Slime HealthComponent death handling supplies enemy_type_id once. Dungeon Slime variants inherit the same metadata without changed AI.
- TALK_TO_NPC: npc_id emits only after dialogue successfully begins. Walking nearby does not count; repeated conversations cannot exceed the requirement.
- REACH_LOCATION: QuestLocationTrigger emits location_id for a living unlocked NORMAL player on entry. Arrival after a scene fade checks overlaps on transition_finished. trigger_once is per loaded trigger instance; repeated progress is still clamped. Events before acceptance are not retained. Development shrine trigger allows re-entry.
- INTERACT_WITH_OBJECT: an optional object_id emits when the existing interactable successfully acquires its scoped interaction lock. This counts accepted interaction, even if later dialogue/animation is cancelled; it does not imply its reward/animation finished.

Only ACTIVE matching objectives change. No per-frame world polling or general EventBus is added. Auto-completion is deferred outside synchronous inventory mutation. A capacity-blocked automatic reward retries after inventory or Yen changes; a health reward requiring a living player needs a later completion attempt if no suitable player exists.

## Offers, hand-in, and rewards

An optional QuestOffer child configures quest ID plus offer, active reminder, ready turn-in, completed, and unavailable dialogue resources. NPC base code delegates generically. After offer lines, minimal Yes/No buttons appear. Yes accepts; No leaves AVAILABLE. Interact advances lines with release guards; Enter/Space/controller south confirms choices. Choice cancellation leaves the offer available.

Ready dialogue must finish normally before hand-in. Damage, death, actor removal, or cancellation preserves the charm and grants no reward. Inventory.can_exchange_quest_items preflights required QUEST_ITEM ownership and all reward capacities; exchange_quest_items commits removals/additions together. Terminal state is reserved before synchronous inventory callbacks to prevent duplicate turn-in. Failure preserves ownership/state; health restoration clamps via HealthComponent and never revives. Completing prerequisites immediately refreshes availability.

QUEST_ITEM was appended to the existing category enum. Old Lucky Charm is unique (limit one), has no Use action, cannot be discarded or removed through ordinary remove_item, and appears under inventory Key Items. Quest-specific consumption uses the validated exchange; KEY/DUNGEON_ITEM removal is still protected. No equipment or reward skill systems are introduced. Phase 8 adds separate Yen/shop infrastructure.

## Journal

QuestJournal is a persistent CanvasLayer with Active/Completed tabs, list, scrollable details, progress, ready instruction, empty state, and Close. Available/failed quests are not listed. L or standard gamepad left-stick click toggles via `quest_journal`; Escape/controller east closes. Arrows/D-pad/left stick and Tab navigate; focus the details panel to scroll with up/down, then use left to return to the list. The mouse also works.

It uses the existing scoped Player interaction lock: movement, attacks, world interactions, inventory opening, and scene travel are blocked while open. Enemies continue simulating. Hurt/death closes it without clearing that state. Notifications reuse InventoryScreen's existing toast. There is no permanent tracker, pinning, sorting, or waypoint UI.

## A Small Favor walkthrough

1. Reload an already-open Godot project after reviewing unsaved tabs. Run `game/world/districts/transition_test/test_exterior.tscn` with F6. F5 remains the original startup district, which has no quest test area.
2. Mrs. Sato is at (96, 105), west of the house. Stand nearby, face her, press E/controller west, and advance the three offer lines. Select No first: the quest stays AVAILABLE and the charm stays hidden. Talk again and select Yes.
3. Open L/L3. Active shows A Small Favor (`a_small_favor`) and 0 / 1 collection progress. Close, then enter/exit the house without stopping; the active quest and offer reminder persist.
4. Visit the placeholder shrine southeast of Mrs. Sato; touch the charm at (176, 263). It uses the existing pickup logic. Inventory contains Old Lucky Charm (`lost_lucky_charm`), with description “A worn little charm. Mrs. Sato must have carried it for a long time.”
5. Verify “Quest Updated: Return to Mrs. Sato.” The journal shows completed collection plus “Return the lucky charm to Mrs. Sato.” State stays ACTIVE, ready for turn-in. Extra events cannot increase 1 / 1.
6. Return, start her “You found it!” conversation, and finish all three lines. Successful hand-in removes the charm, grants Small Healing Drink ×2 plus ¥500 (added in Phase 8), and marks COMPLETED. If the drink stack or wallet lacks room, no part of the exchange occurs; make room/use drinks, recover, and talk again.
7. Journal Completed lists the quest. Repeat conversation to hear post-completion lines without more rewards. Reload areas without stopping: the charm stays absent and Mrs. Sato keeps completed dialogue.
8. `shrine_rumors_followup` becomes AVAILABLE only now. It is data-only prerequisite verification; no offer, shrine keeper, or playable follow-up is provided.

DevTest instances the same area with Mrs. Sato at (640, 125) and charm at (720, 283). Existing combat and interaction tests remain present. Shrine marker object ID is old_shrine_memorial; location ID is old_shrine_gate. Dialogue resources are configured on scenes, never branches in QuestManager or Player.

## Persistence and limits

QuestManager, Inventory, and DungeonManager each retain their own session state across scene changes. Quest pickups/NPCs query that state when loaded. Restart without loading starts fresh. Phase 9 manual saves restore quest state, clamped objective progress, readiness, and prerequisites silently; completed rewards never replay. NPC/quest pickup reconstruction reads restored runtime state. Existing combat death behavior is preserved, with manual Load/New Game available. Phase 8 now adds Yen/shop gameplay separately; there are still no advanced branching, markers, skill/cosmetic rewards, relationships, daily/timed/procedural quests. Phase 9 save details and exact ready/completed acceptance routes are in [SAVE_FORMAT.md](../documentation/SAVE_FORMAT.md).

Headless validation covers real input events and all five objective types with temporary external fixtures, full quest flow, atomic capacity failure, cancellation/reentrancy, journal focus/scroll, scene restoration, and prior phase regressions. Fixture definitions are not registered in shipped content. Manually verify text/clipping, placeholder readability, nearest/integer scaling, focus indications, and a physical controller on your display. Godot 4.7.2 is the installed tested engine; compatibility with every other Godot 4.x release is not asserted.

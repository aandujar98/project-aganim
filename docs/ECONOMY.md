# Yen and reusable shops — Phase 8

## Currency and formatting

Wallet Autoload owns session Yen, independently of UI/shop NPCs. Its exported starting_yen defaults to ¥3,000 for development; change the script's exported default for the current script-based Autoload. APIs: get_yen, can_afford, can_add_yen, add_yen, spend_yen, can_exchange_yen, exchange_yen. Add/spend return success; negative amounts/insufficient balance/overflow fail without mutation. Zero amounts are valid no-ops. Balance is bounded to 0..999,999,999; this is a defensive development limit, not economy balance.

exchange_yen(cost, reward, optional_commit) reserves the balance and blocks re-entry while its all-or-nothing commit runs; failed commit restores the previous balance without yen_changed. Inventory's existing add/exchange methods provide that commit guarantee. Arbitrary external commit callbacks must obey it. A successful changed balance emits yen_changed(new_amount). Wallet remains a single-currency runtime authority; Phase 9 serializes its current balance through explicit manager APIs.

YenFormat.format supplies ¥0, ¥300, ¥3,000, ¥25,500 with separators. CurrencyHUD is a small top-right CanvasLayer using a shadowed label, integer viewport scaling, and signal updates. Shop labels and purchase/quest notifications use the same formatter. No per-frame currency polling or release cheat controls are added. Wallet.add_yen(1000) remains available as a development API.

## Static shop definitions

ItemData.buy_price defaults to zero. A nonpositive default means not normally purchasable. Only explicit ShopData entries can be bought; registering an item alone never puts it in a store. Existing key/quest/dungeon item definitions keep zero prices and are absent from Kagami Mart.

ShopData is a Resource with stable id, display_name, and typed ShopEntryData entries. Each entry has item_id, price_override, and stock. Exactly -1 means use item default price / unlimited stock respectively; values below -1 are rejected as malformed. Explicit price_override = 0 permits a free item, even when its default is non-purchasable. stock = 0 represents SOLD OUT; a positive integer is limited stock.

ShopManager loads the explicit SHOP_PATHS list once and supports register_shop for configured definitions. It validates stable IDs, item references, prices within the wallet range, stock sentinel, null entries, and duplicate item IDs. A malformed/duplicate entry rejects the entire shop with a useful warning. Zero-entry shops are valid and show an empty state. One entry per item per shop keeps runtime addressing unambiguous; no demand/supply pricing is added.

## Runtime stock and purchasing

ShopManager owns separate stock dictionaries by stable shop ID + item ID. Static resources are not mutated. get_shop/get_entry expose definitions; resolve_price is the single pricing path; get_stock returns session stock; purchase_reason gives clear feedback; buy_item purchases exactly one.

Transaction sequence:

1. Resolve configured entry and real item/price; reject unavailable entries.
2. Check stock, current Yen, and Inventory.can_add_item.
3. Guard nested purchases and reserve limited stock.
4. Wallet.exchange_yen reserves the cost and calls existing Inventory.add_item.
5. Inventory commits one item and emits its existing events while wallet/stock are already reserved consistently.
6. If addition fails, roll balance/stock back and emit no success event. Otherwise emit stock_changed/item_purchased, refresh UI, and report the formatted purchase.

Nested callbacks cannot spend reserved currency, remove the item during its guarded addition, or buy again. Each explicit released/new confirm press intentionally buys one; no quantity selector or duplicate suppression across separate legitimate inputs. Failed funds/stock/capacity checks change nothing. Existing inventory has no slot limit; its existing per-item stack limit (99 for these items) and unique-item rules remain. Sold-out entries stay visible. Unaffordable/sold-out rows dim; selection is allowed to explain failure.

Prices are temporary: Small Healing Drink ¥300 unlimited; Spirit Fragment ¥500 stock three; Energy Soda ¥250 unlimited. Energy Soda uses the existing heal_player effect for one HP, with no stamina/buffs. It stacks normally and can be used from Inventory; full-health use retains the item.

## Merchant and UI

Convenience Store Clerk has stable npc_id kagami_mart_clerk and optional MerchantOffer child configured with dev_convenience_store and greeting resource. NPC base delegates generically; there is no purchasing logic in dialogue scripts or store-name branch in ShopManager. Interaction begins existing dialogue “Welcome! Need anything?”; advance once to Buy/Leave. Buy opens ShopScreen only after normal dialogue closure/releasing the NPC lock. Leave/cancel immediately returns control. Quest dialogues keep their default Yes/No labels.

ShopScreen is a persistent CanvasLayer with shop title/Yen, item list (icons/name/price/limited stock), selected icon/name/description/price/owned count/stock/feedback, Buy 1, and Leave. Refresh follows opens, selection, purchases, wallet/inventory/stock signals; guarded mutation signals schedule a deferred detail refresh. Empty shops show “Nothing is available right now.” with focused Leave. Purchase feedback appears in the shop and reuses the existing toast.

Up/Down or D-pad selects, Enter/Space/controller south confirms, Tab or focus directions reaches buttons, Escape/controller east closes. Release/echo guards prevent opening-confirm leakage and repeated keyboard purchases. UI uses named actions, no physical-key checks. Closing returns player control; confirm does not leak a sword swing.

The existing Player.begin_interaction/end_interaction and cancellation hooks lock movement, attack, world interaction, inventory, journal, and travel. No new pause architecture is added. Enemies keep simulating; damage/death/removal closes UI without overriding HURT/DEAD. Opening during combat/other UI/fades is rejected.

## Kagami Mart scene

`game/world/interiors/kagami_mart/kagami_mart.tscn` is an existing-contract WorldArea with one Player, CameraBounds (384×216), default/store_inside SpawnPoints, solid walls, two shelves, clerk/counter, shared DialogueUI, and ExitDoor. Placeholder polygons/SVG item icon require no external art or plugins. The clerk owns the counter collision so the existing facing/obstruction interaction check works across it.

TestExterior adds StoreFacade, StoreLabel, StoreDoor at (590, 120), and store_front spawn at (590, 160). Its house, region, dungeon, quest, and pickup content remains intact. StoreDoor targets store_inside at (192, 138); ExitDoor targets store_front. F5 remains the original startup district. Direct F6 on the store also works; the full persistence route starts from TestExterior.

## Quest Yen rewards

QuestRewardData appends YEN after ITEM/HEALTH_RESTORE/NOTHING, preserving prior serialized enum indexes; its amount range supports Yen-sized values. QuestManager sums rewards with overflow checks, preflights wallet + inventory, reserves COMPLETED, then wraps the existing atomic item hand-in with Wallet.exchange_yen. Failure keeps the quest ACTIVE-ready, charm owned, and items/Yen unchanged. Success emits feedback through shared formatting and cannot reward twice. Auto-completion is deferred; inventory/Yen signals retry capacity-blocked rewards after the guards clear.

A Small Favor now grants two Small Healing Drinks plus ¥500. Offer/objective/reminder/turn-in/post-completion/prerequisite behavior is preserved. A full drink stack or wallet cap blocks the whole reward. No skill rewards or currency pickups are introduced.

## Exact manual test sequence

1. Review unsaved editor tabs, reload an already-open project to register Wallet, ShopManager, ShopScreen, CurrencyHUD. Open TestExterior and F6 for a fresh ¥3,000 session. F5 does not contain the store entrance.
2. Walk northeast to Kagami Mart; approach (590, 120) from below, face Up, Interact (E/controller west). Avoid the optional outdoor sample pickups if following the exact owned counts below.
3. Inside, approach clerk at (272, 68) from the south across the counter. Interact, advance greeting, choose Leave once. Verify control returns. Talk again and choose Buy; no item is purchased on opening.
4. Select drink and confirm once: balance ¥2,700, Owned 1. Try movement, attack, E, I, L and scene travel: all remain locked. Release between confirmations; keyboard echo does not buy repeatedly.
5. Select Spirit Fragment, buy three separately: balance ¥1,200, Owned 3, stock SOLD OUT. Try a fourth: balance/items/stock unchanged, SOLD OUT feedback.
6. Select Energy Soda, buy once: balance ¥950, Owned 1. Return to drinks and buy three: balance ¥50, drinks Owned 4. Attempt another: insufficient Yen, unchanged items and balance.
7. Back/Escape or Leave closes; inventory shows purchases. If hurt, use soda to heal one HP through existing inventory. At full health it remains owned. No stamina effect.
8. Face the south ExitDoor at (192, 176) from above (Down), Interact. Return at (590, 160), then re-enter. Wallet remains ¥50, fragment stock stays SOLD OUT, inventory persists.
9. Close shop, exit, and complete A Small Favor without stopping: Mrs. Sato (96, 105), Yes; shrine charm (176, 263); return and finish final dialogue. Balance becomes ¥550 and drinks 6 if following this route without using them. Post-completion conversations cannot add more Yen/items.
10. Verify controller D-pad/confirm/back, keyboard Tab/Space/Enter, icons/text/clipping, focus marks, HUD crispness, and store collisions/camera bounds on your display. Restart without loading starts fresh; Phase 9 Load restores saved wallet/items/limited stock. See [SAVE_FORMAT.md](../documentation/SAVE_FORMAT.md).

## Persistence, verification, and limits

Wallet, Inventory, QuestManager, and ShopManager retain independent session state across house/store/dungeon transitions. Stock reconstructs from ShopManager when the UI opens; NPC scenes own no critical economy state. Phase 9 manual saves preserve the wallet and limited stock; unlimited stock is derived from definitions. Existing combat death behavior is preserved, with manual Load/New Game available.

Headless tests exercise actual entrance/exit and merchant keyboard/controller events, stacking, insufficient funds/sold out, mixed quest rewards, forced addition failure rollback, synchronous re-entry, UI locking/cancellation/removal/death, empty/malformed/free/unique shops, wallet limits, automatic Yen reward retry, and prior movement/combat/dialogue/inventory/travel/quest/dungeon regressions. Test-only fixtures live outside the repository. Physical-controller/visual acceptance remains manual.

No selling/trade-ins, dynamic economy, coupons/discounts, multiple currencies, bank/credit systems, equipment/cosmetic shops, crafting, rotating stock, final art. Phase 9 adds manual save/load separately; no autosave or cloud/platform save integration.

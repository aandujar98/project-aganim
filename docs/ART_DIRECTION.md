# Art direction — Project Aganim visual bible

**Target:** a night-time modern Japanese city in 16-bit SNES-inspired top-down pixel art, with dense modern detail and warm lantern glow.

**Visual reference:** the "Sakura City" gameplay mockup. The project replicates its framing, density, palette, HUD layout and composition. Everything is drawn from scratch. Real-world branding in the mockup, such as the JR logo, is replaced with original designs: the station uses an original blossom-and-track emblem. Never copy or trace Nintendo/Zelda (or any other) sprites, maps, UI or characters.

**Validation scene:** `game/world/districts/visual_test/visual_test_district.tscn` (Sakura City). Open it and press **F6**.

---

## 1. Internal resolution

- **640 × 360** (16:9), changed from 384 × 216 for the mockup replication.
- The mockup is drawn at 3 screen pixels per art pixel, which makes it about 512 × 341 art pixels (3:2), with 24 px characters and 16 px tiles. At 640 × 360 the vertical framing matches the mockup almost exactly: characters fill about 7% of screen height. The extra width is the normal 16:9 widening.
- Integer scales: 2× = 1280 × 720 (default window), 3× = 1920 × 1080, 4× = 2560 × 1440, 6× = 3840 × 2160. All four fill the screen exactly, with no letterbox.
- The view is 40 × 22.5 tiles. Rooms smaller than the view (older interiors at 384 × 216) are centred by `CameraBounds`, with the dark clear colour around them.

## 2. Tile size

- **16 × 16** grid. One art pixel is one world pixel.
- **Atlas:** `art/tilesets/city_tiles.png`. **TileSet:** `resources/tilesets/city_tileset.tres`. Physics layer 0 is the World collision layer.
- **Tile families:**
  - pavers ×4
  - tactile paving (dots, vertical lines, horizontal lines)
  - asphalt ×3, lane markings, zebra crossings, curbs, manhole
  - station floor, stone stairs, stone slabs
  - water ×3 plus a petal variant, canal wall and coping, rail track
  - kawara roofs (9-slice), flat roofs (9-slice)
  - wood planks with lit and dim shoji, ramen storefront and door, dark plaster with window and shutter
  - concrete windows (warm, pink, blue, dark), brick, station stone panel
  - konbini glass and door, foliage, pink foliage
- **Layers per area:**
  - `Ground`: no collision.
  - `GroundDetail`: decals such as petals.
  - `Buildings`: collision on; roofs, walls, foliage, water.
  - `YSort`: contains `Props` and `People`.
- Buildings use 3/4 top-down: a roof seen from above, then one or more facade rows. The structure never extends above its own collision footprint, so `Buildings` can draw beneath the y-sorted actors.

## 3. Player sprite (locked design)

The protagonist frames are **cut directly from the official character sheet** (the "Project Aganim — Main Protagonist" sheet) and are not redrawn:

- Each cell's background is removed and the frame downsampled 2:1 to game scale.
- The idle panel, which is drawn larger on the sheet, is resampled to the walk/run height.
- Do not redesign or repaint the frames; update them by re-extracting from the sheet.

| Item | Standard |
| --- | --- |
| Asset | `art/characters/player/player_spritesheet.png` (384 × 256) |
| Canvas | 32 × 32 per frame, all frames identical size |
| Visible body | about 19–23 wide × 26–29 tall, as drawn on the sheet |
| Ground line | lowest foot on canvas y = 29. Sprite2D `centered = false`, `offset = (-16, -30)` |
| Node origin | **at the feet**. The Player's y-sort and collision both use it |
| Collision | 12 × 8 rectangle at (0, -4): feet only |
| Hurtbox | 16 × 22 at (0, -12) |
| Shadow | `art/characters/player/player_shadow.png` 16 × 5 at (0, -1), a sibling of `Visuals` |
| Sword | separate state; never part of idle/walk/run frames |

## 4. NPC sprites

NPCs are **cut directly from the "NPC Examples (Town)" panel of the official character sheet**. They use the same method and the same 2.75:1 scale as the protagonist reference, so relative sizes match the sheet: NPCs stand about 21–25 px tall, while the protagonist's bigger hair makes him 26–28 px.

- **Layout:** the same 32 × 32 canvas, feet-on-y = 29 ground line, feet origin and 8 × 8 sheet layout as the player. Row 0 is the front view (idle, static) and row 4 the back view.

| Sheet | Character | Back view |
| --- | --- | --- |
| `npc_female_a` | Female A (teen) | yes |
| `npc_male_a` | Male A (teen) | yes |
| `npc_businessman` | Businessman | yes |
| `npc_station_staff` | Station staff | yes |
| `npc_school_girl` | School girl | front only |
| `npc_police` | Police | front only |
| `npc_old_man` | Old man | front only |
| `npc_elderly_woman` | Elderly woman | front only |
| `npc_elderly_woman_b` | Elderly woman (variant) | front only |
| `npc_child` | Child | front only |
| `npc_resident` | Male A, used by `npc.tscn` | yes |
| `npc_mrs_sato` | Elderly woman | front only |
| `npc_kagami_clerk` | Female A | yes |

- **Front-only NPCs:** their back views on the sheet blend into the dark background and could not be cut cleanly, so these NPCs only face the camera.
- **Not yet extracted:** Shop Clerks, Shrine Maiden, Student (M/F), Tourist and Ramen Chef sit on glowing backgrounds. They need transparent-background art, like the protagonist frames.
- **Talkable NPCs:** `game/npcs/npc.tscn` (Interactable + dialogue); swap the `Visual` sheet per character.
- **Crowd:** `game/npcs/ambient_npc.tscn` (`AmbientNPC`), with exports `sheet`, `facing`, `accessory` and `accessory_offset`.

## 5. Chibi proportions

- **Head plus hair:** follows the protagonist reference, about 55%. A general rule of 45–50% applies to other humanoids. Torso is about 25%, and legs plus shoes about 18%.
- **Features:** eyes are 2 × 3 px with a highlight; mouths are omitted or a single shade pixel; hands are a 2 px skin cluster at the cuff.
- **Outline:** 1 px dark navy (`#0b0a18`–`#1b1a2e`), never pure black.
- **Shading:** hue-shifted shadows (toward blue/purple) with warm highlights, shaded in pixel clusters rather than gradients.

## 6. Camera zoom

- **1.0** (integer), from `resources/shared/camera/default_camera_profile.tres` via `GameCamera`. With 640 × 360 this gives the mockup's framing.
- Fractional zoom (1.25, 1.33) was tested at 384 × 216 and rejected: it draws art pixels at uneven sizes ("mixels"). Change framing by changing the internal resolution, never with fractional zoom.
- **Profile fields:** `zoom`, `framing_offset` (0, -10), `snap_to_pixels`.

## 7. Texture filtering

- The project default is Nearest (`rendering/textures/canvas_textures/default_texture_filter = 0`), unchanged.
- PNGs import Lossless with mipmaps off. Never use Linear filtering, mipmaps, or VRAM/lossy compression on pixel art.

## 8. Scaling and rendering settings

| Setting | Value | Note |
| --- | --- | --- |
| `display/window/size/viewport_width/height` | **640 / 360** | changed from 384 / 216 |
| `display/window/size/window_width/height_override` | **1280 / 720** | changed from 1152 / 648 (still 2×) |
| `display/window/size/min_width/height` | **640 / 360** | changed |
| `rendering/environment/defaults/default_clear_color` | **(0.039, 0.043, 0.09)** | added: dark navy behind undersized rooms |
| `display/window/stretch/mode` | viewport | unchanged |
| `display/window/stretch/scale_mode` | integer | unchanged |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | true | unchanged |

**UI adaptation for the new resolution:**

- The legacy 368 × 200 menus (inventory, journal, shop, save slots) are anchored to screen centre.
- The dialogue panel is anchored bottom-centre.
- `CurrencyHUD` is anchored top-right.
- Debug instruction labels are anchored to the bottom edge.
- `CameraBounds` centres rooms that are smaller than the view.

## 9. Pixel-perfect rules

- Place tiles, props, spawns and actors on whole pixels. Keep sprite offsets integers.
- Don't scale, rotate or skew art at runtime. The DevDungeon lieutenant and guardian still use scaling; this is legacy and needs dedicated art.
- Animate by swapping frames.
- Glows use pre-rendered sizes (`glow_48/72/96/144.png`), never scaled sprites.
- HUD text uses the proportional 7 px pixel font (`PixelText`, `art/ui/hud/pixel_font.png`), which has a baked outline. Menus and dialogue still use Godot's default font.

## 10. Environment object sizes

Props are scenes in `game/world/props/`:

- the root is a StaticBody2D (World layer), or a Node2D for decor
- a `Sprite` child with `centered = false` and `offset = (-w/2, -base_y)`
- footprint collision shapes
- optional `Glow` sprites

**The root origin is the ground contact point.** Place props under `YSort/Props`.

| Object | Canvas (px) | Collision |
| --- | --- | --- |
| Street lamp (lantern head) | 12 × 44 | 4 × 3 |
| Utility pole (crossarms, transformer) | 24 × 90 | 4 × 3 |
| Torii | 112 × 86 | two 13 × 8 pillar bases |
| Fox statue on pedestal | 18 × 32 | 16 × 6 |
| Shrine banner (神社) | 14 × 46 | 3 × 3 |
| Hokora (small shrine) | 44 × 56 | 38 × 12 |
| Stone lamp | 14 × 34 | 10 × 5 |
| Cherry tree / green tree | 60 × 58 / 44 × 52 | trunk 8 × 5 |
| Bush / large bush | 20 × 16 / 34 × 24 | 16–30 × 5–6 |
| Vending machine (red/blue) | 16 × 32 | 16 × 6 |
| Ticket gate | 14 × 24 | 10 × 6 |
| Railing segment | 32 × 18 | 32 × 4 |
| Train car | 100 × 52 | 100 × 12 |
| Bicycle, AC unit, planter, menu board, game kiosk | 14–28 wide | small footprints |
| Signs: ラーメン, 居酒屋, カラオケ, ラーめん, コンビニ band, station sign, noren, chōchin, pole banners | 8–128 wide | decor only |

- **Overhead wires:** `Line2D`, 1 px, no antialiasing, under a `Wires` node at z 30.
- **Petals:** `CPUParticles2D` using the 3 × 2 `sakura_petal.png`.

## 11. Lighting rules

- **The night palette is painted into the art.** No CanvasModulate is used: dark navy roofs, mauve pavers and warm windows are already in the pixels.
- **Light is additive glow sprites.** They use `resources/shared/materials/additive_glow.tres` (CanvasItemMaterial, blend Add) with the stepped `art/effects/glow_*.png` halos at z 20.
  - Godot's `PointLight2D` multiplies with surface colour, so on a deliberately dark palette it barely shows.
  - Additive halos reproduce the mockup's lantern bloom, keep crisp pixel bands, and have no per-item light limits.
- **Placement:** put halos on the emitting part (lamp heads, lanterns, kiosk signs, shrine door). Add a faint pool at a lamp's base. Large faint area glows go over lit interiors and storefronts (`AreaGlows`).

| Source | Colour | Halo | Alpha |
| --- | --- | --- | --- |
| Street lamp head | warm (1, 0.6, 0.24) | 48 | ~0.5 |
| Street lamp pool | warm | 72 | ~0.14 |
| Chōchin / torii lanterns | red-orange / warm | 48 | ~0.44 |
| Vending machine | cool (0.7, 0.85, 1.0) | 48 | ~0.28 |
| Karaoke / game signs | red / purple | 48–72 | ~0.25–0.32 |
| Station interior, konbini front | warm / cool | 144 | 0.14–0.16 |

- No bloom post-processing, normal maps or smooth gradients. The supernatural palette (purples, cyan, red moon) is reserved.

## 12. HUD positioning

`game/ui/hud/game_hud.tscn` is a CanvasLayer on layer 5, instanced per WorldArea.

| Region | Content |
| --- | --- |
| Top-left (8, 8) | `HeartMeter`: 12 × 11 hearts on a 14 px pitch, 1 health per heart (`health_per_heart` 2 enables half hearts) |
| Top-left (8, 22) | `MagicMeter`: 12 × 12 glossy blue orbs; hidden until fed (`magic_preview` for test scenes) |
| Top-left (8, 39) | Yen (`PixelText`). GameHUD hides `CurrencyHUD` while present |
| Top-right (from x = 448) | Four 26 × 26 `QuickSlot`s on a 30 px pitch: gold frame when selected, 14 × 13 A/Y/X/R badges, outlined quantities |
| Top-right (574, 8) | `Minimap` 60 × 74: map window 54 × 58, name bar, quarter-scale area render, blue player arrow |

- No "HP" or "MP" text.
- Slots are display-only. `slot_previews` on GameHUD (`{"SlotY": [icon, quantity]}`) sets presentation-only contents; Sakura City uses bomb ×10, green potion ×3 and boots. Real slots use `item_id` with Inventory counts.
- Keep the bottom 80 px clear for the dialogue panel.

## 13. Colour philosophy

| Element | Colours |
| --- | --- |
| Outlines and shadows | deep navy `#120f24`, `#1b1a2e` |
| Kawara roofs | `#1d295a` / `#33468a` |
| Flat roofs | `#222b56` |
| Pavers | mauve-grey `#6c6377` with dark mortar |
| Tactile paving | ochre `#c48d2c` |
| Asphalt | `#47445c` |
| Warm light | windows, lanterns, shoji `#ffd06a`, `#f7b64a` |
| Shrine reds | `#cf2534` |
| Blossoms | `#f07fb4` |
| Foliage | `#2e6b35` |
| Canal | `#163a82` |

- **Saturation is reserved for points of interest:** signage, lanterns, shrine red, blossoms, the player's blue hoodie.
- **Original branding only:** the konbini uses generic stripes and the word コンビニ; the station uses an original emblem.

## 14. Animation frame conventions

- **Protagonist sheet:** 32 × 32 cells, **12 columns × 8 rows**.
  - **Rows:** 0 down, 1 down-right, 2 right, 3 up-right, 4 up, 5 up-left, 6 left, 7 down-left
  - **Columns:** 0–3 idle, 4–7 walk, 8–11 run
  - Frame index = `row * 12 + column`.
- **Frames:** every direction uses its own frames from the sheet (no mirroring). Idle is the sheet's single idle pose per direction, held for 4 frames. Walk and run are the sheet's 4-frame cycles, keeping their original bob and stride.
- **Animation names** (on the Player's `AnimationPlayer`, animating `Visuals/Sprite:frame`):
  - `idle_<dir>`, `walk_<dir>`, `run_<dir>`
  - `<dir>` is one of `down`, `down_right`, `right`, `up_right`, `up`, `up_left`, `left`, `down_left`

| Animation | Frame time | Contents |
| --- | --- | --- |
| idle | 0.25 s (4 fps) | the sheet's idle pose (static) |
| walk | 0.12 s (≈ 8.3 fps) | the sheet's 4 walk frames |
| run | 0.09 s (≈ 11 fps) | the sheet's 4 run frames |

- **Facing:** the sprite faces 8 directions (`sprite_direction`, snapped from the movement input). Gameplay facing (`facing_direction`: sword, interaction, saves) stays cardinal. Facing set from outside (spawns, transitions, loads) resets the sprite direction.
- **Run:** plays while the existing `sprint` action is held (Ctrl / left shoulder) at `run_speed` 135 px/s (walk is 90 px/s). Both are exported on the Player.
- **NPC sheets:** 8 × 8 cells (idle and walk only), down and up rows.
- **Future protagonist sheets:** `player_attack.png`, `player_dodge.png`, `player_hurt.png`, `player_interact.png`, `player_item.png`, `player_death.png`. Keep the same row order and 4-frame groups.

## 15. Importing future pixel-art assets

1. Draw at 1× on the grids above. Export RGBA PNG with no scaling.
2. **File location:**
   - characters → `art/characters/`
   - tiles → `art/tilesets/`
   - props → `art/environments/props/`
   - glows and particles → `art/effects/`
   - HUD → `art/ui/hud/`
   - area minimaps → `art/ui/minimap/`
   - item icons (16 × 16) → `art/items/`
3. Keep Godot's default 2D import (Lossless, no mipmaps). Commit the `.import` files.
4. **Characters:** keep the row order, the 32 × 32 cells and the y = 30 ground line. The player sheet uses 12 columns (idle/walk/run); NPC sheets use 8.
5. **Props:** origin at ground contact, a footprint collision, glows on the emitter, and a place under `YSort/Props`.
6. **Tiles:** append to the atlas without moving existing tiles, and add collision for solid tiles.
7. **Minimap:** render the composed area at quarter scale with brightness +35%, and set it as the WorldArea HUD's `minimap_texture`.
8. **Density:** one art pixel per world pixel, no mixed resolutions, and a 1 px dark outline on characters and freestanding props.

## Current art status

- All art in `art/characters`, `art/tilesets`, `art/environments/props`, `art/effects`, `art/ui` and the new `art/items` icons (starter sword, bomb, green potion, dash boots) is original first-pass production art made to match the Sakura City mockup.
- The bomb, potion and boots icons are HUD previews only; those items do not exist yet.
- Older sandbox scenes (DevTest, transition test, DevDungeon, Kagami Mart interior) keep their placeholder polygons. They use the new character sprites but are not y-sorted.

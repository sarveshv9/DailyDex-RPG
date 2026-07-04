# DailyDex RPG — Visual Style Guide

## Global Rendering
- **Base Resolution:** 320 × 180
- **Stretch Mode:** `viewport` (Integer scaling)
- **Palette:** Warm, saturated earth tones. Use `CanvasModulate` for time-of-day tints.

## Environment
- **Grid Size:** 16×16 pixels per tile.
- **Tilesets:** Break up repeating patterns with random detail tiles (pebbles, weeds). Ensure grass edges transition smoothly into dirt.

## Character Sprites (Overworld)
- **Size:** 16×16 per frame (canvas can be larger if needed, e.g. 24x24 for tall hair/hats).
- **Animations:** 
  - 4 Directions (Down, Left, Right, Up)
  - 4 Frames per direction (Idle, Walk 1, Idle, Walk 2)
  - Layout: `hframes = 4`, `vframes = 4`

## Creature Sprites (Battle)
- **Size:** 64×64 pixels.
- **Style:** Detailed, Pokemon-style portraits. Can exceed 64x64 if necessary, but UI layouts assume roughly this size.
- **VFX:** Battles use tweened jumps, hit flashes (white modulate), and position shakes.

## UI Styling
- **Theme:** Clean, modern flat design with subtle borders.
- **Backgrounds:** `Color(0.12, 0.12, 0.15, 0.95)` (Dark grey-blue, slight transparency).
- **Borders:** 2px width, `Color(0.85, 0.85, 0.80)` (Off-white/cream).
- **Corners:** 4px to 6px corner radius.
- **Highlights:** `Color(1.0, 0.85, 0.4)` (Gold/Yellow) for titles and selected items.

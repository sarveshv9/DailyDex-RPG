# DailyDex-RPG Asset Decisions

## World Tileset
- **Source:** `_archive_old_project/resources/tilesets/level.tres` (and images in `assets/tilesets/levels/`)
- **Reasoning:** The archive project's tileset was already fully built with thousands of collision polygons, z-indexes, and data layers perfectly calibrated for a Pokemon clone. Rebuilding this by hand would be extremely tedious.
- **Implementation:** `build_test_map.gd` strips out broken dependencies from the archive's old `.tscn` levels and generates a clean `test_map.tscn` that properly utilizes the `.tres`.

## Player Character Sprite
- **Source:** `pokemon_emerald_godot-main/player_assets/player.png`
- **Reasoning:** Extremely clean, iconic GBA Emerald style sprite sheet with perfect 16x16 frames, making animation logic (`build_player.gd`) trivial.

## NPC Sprites
- **Source:** `assets/sprites/npc/` (migrated from `_archive_old_project/npc_assets/`)
- **Reasoning:** Fully formatted 16x16 4-directional sprites perfectly scaled for the game. Matches the player's Emerald style.

## Battle UI and Sprites
- **Source:** `assets/battle_assets/` (migrated from `_archive_old_project/battle_assets/`)
- **Reasoning:** Contains complete UI panels, Pokemon battle sprites, pokeballs, and attack cursors.

## Dialogue Box UI
- **Source:** `pokemon_emerald_godot-main/assets/dialogue.png`
- **Reasoning:** A fully complete and clean dialogue UI that matches the screen scale and retro aesthetic without needing scaling modifications.

## Font
- **Source:** `pokemon_emerald_godot-main/fonts/pkmnem.ttf`
- **Reasoning:** This is the authentic Pokemon Emerald font, essential for the retro aesthetic.

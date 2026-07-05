#!/usr/bin/env python3
"""
Converts pokeemerald move data into a Godot-friendly JSON file.
Parses: battle_moves.h, moves.h
"""
import re
import json
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POKE = os.path.join(BASE, "_unused_assets", "pokeemerald-master")

TYPE_NAMES = {
    0: "Normal", 1: "Fighting", 2: "Flying", 3: "Poison", 4: "Ground",
    5: "Rock", 6: "Bug", 7: "Ghost", 8: "Steel", 9: "Mystery",
    10: "Fire", 11: "Water", 12: "Grass", 13: "Electric", 14: "Psychic",
    15: "Ice", 16: "Dragon", 17: "Dark"
}

# Gen 3 physical/special split is by type, not by move
# Types 0-8 are Physical, 10-17 are Special (9=Mystery is neither)
PHYSICAL_TYPES = {0, 1, 2, 3, 4, 5, 6, 7, 8}  # Normal through Steel
SPECIAL_TYPES = {10, 11, 12, 13, 14, 15, 16, 17}  # Fire through Dark

def parse_move_names():
    """Parse MOVE_X → ID mapping and generate display names."""
    path = os.path.join(POKE, "include", "constants", "moves.h")
    moves = {}
    with open(path) as f:
        for line in f:
            m = re.match(r"#define\s+(MOVE_\w+)\s+(\d+)", line)
            if m and m.group(1) not in ("MOVES_COUNT", "MOVE_UNAVAILABLE"):
                name = m.group(1)
                val = int(m.group(2))
                # Generate display name: MOVE_FIRE_PUNCH → "Fire Punch"
                display = name.replace("MOVE_", "").replace("_", " ").title()
                moves[name] = {"id": val, "display_name": display}
    return moves

def parse_type_constant(type_str):
    """Convert TYPE_FIRE etc. to int."""
    type_map = {
        "TYPE_NORMAL": 0, "TYPE_FIGHTING": 1, "TYPE_FLYING": 2, "TYPE_POISON": 3,
        "TYPE_GROUND": 4, "TYPE_ROCK": 5, "TYPE_BUG": 6, "TYPE_GHOST": 7,
        "TYPE_STEEL": 8, "TYPE_MYSTERY": 9, "TYPE_FIRE": 10, "TYPE_WATER": 11,
        "TYPE_GRASS": 12, "TYPE_ELECTRIC": 13, "TYPE_PSYCHIC": 14, "TYPE_ICE": 15,
        "TYPE_DRAGON": 16, "TYPE_DARK": 17
    }
    return type_map.get(type_str, 0)

def parse_battle_moves(move_names):
    """Parse battle_moves.h for detailed move data."""
    path = os.path.join(POKE, "src", "data", "battle_moves.h")
    with open(path) as f:
        content = f.read()

    moves = {}
    # Match each move block
    pattern = r'\[(MOVE_\w+)\]\s*=\s*\{([^}]+)\}'
    for m in re.finditer(pattern, content):
        move_name = m.group(1)
        block = m.group(2)

        if move_name not in move_names:
            continue

        move_id = move_names[move_name]["id"]
        display_name = move_names[move_name]["display_name"]

        data = {
            "id": move_id,
            "name": display_name,
            "internal_name": move_name,
        }

        # Parse effect
        em = re.search(r'\.effect\s*=\s*(\w+)', block)
        if em:
            data["effect"] = em.group(1)

        # Parse power
        pm = re.search(r'\.power\s*=\s*(\d+)', block)
        data["power"] = int(pm.group(1)) if pm else 0

        # Parse type
        tm = re.search(r'\.type\s*=\s*(TYPE_\w+)', block)
        if tm:
            type_id = parse_type_constant(tm.group(1))
            data["type"] = type_id
            data["type_name"] = TYPE_NAMES.get(type_id, "Normal")
            # Gen 3 physical/special by type
            data["category"] = "physical" if type_id in PHYSICAL_TYPES else "special"
        else:
            data["type"] = 0
            data["type_name"] = "Normal"
            data["category"] = "physical"

        # Parse accuracy
        am = re.search(r'\.accuracy\s*=\s*(\d+)', block)
        data["accuracy"] = int(am.group(1)) if am else 0

        # Parse PP
        ppm = re.search(r'\.pp\s*=\s*(\d+)', block)
        data["pp"] = int(ppm.group(1)) if ppm else 0

        # Parse secondary effect chance
        sm = re.search(r'\.secondaryEffectChance\s*=\s*(\d+)', block)
        data["secondary_effect_chance"] = int(sm.group(1)) if sm else 0

        # Parse priority
        pri = re.search(r'\.priority\s*=\s*(-?\d+)', block)
        data["priority"] = int(pri.group(1)) if pri else 0

        # Parse flags
        fm = re.search(r'\.flags\s*=\s*(.+?)(?:,|\n)', block)
        if fm:
            flags_str = fm.group(1).strip().rstrip(',')
            data["makes_contact"] = "FLAG_MAKES_CONTACT" in flags_str
            data["protect_affected"] = "FLAG_PROTECT_AFFECTED" in flags_str
        else:
            data["makes_contact"] = False
            data["protect_affected"] = False

        moves[str(move_id)] = data

    return moves

def main():
    print("Parsing move names...")
    move_names = parse_move_names()
    print(f"  Found {len(move_names)} move definitions")

    print("Parsing battle move data...")
    moves = parse_battle_moves(move_names)
    print(f"  Parsed {len(moves)} moves with stats")

    # Write output
    out_dir = os.path.join(BASE, "assets", "data")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "moves.json")
    with open(out_path, "w") as f:
        json.dump(moves, f, indent=2)

    print(f"\nWrote {len(moves)} moves to {out_path}")

if __name__ == "__main__":
    main()

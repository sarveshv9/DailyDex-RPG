#!/usr/bin/env python3
"""
Converts pokeemerald type effectiveness table into a Godot-friendly JSON file.
Parses: gTypeEffectiveness table from battle_main.c
"""
import re
import json
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POKE = os.path.join(BASE, "_unused_assets", "pokeemerald-master")

TYPE_NAMES = {
    0: "Normal", 1: "Fighting", 2: "Flying", 3: "Poison", 4: "Ground",
    5: "Rock", 6: "Bug", 7: "Ghost", 8: "Steel",
    10: "Fire", 11: "Water", 12: "Grass", 13: "Electric", 14: "Psychic",
    15: "Ice", 16: "Dragon", 17: "Dark"
}

TYPE_MAP = {
    "TYPE_NORMAL": 0, "TYPE_FIGHTING": 1, "TYPE_FLYING": 2, "TYPE_POISON": 3,
    "TYPE_GROUND": 4, "TYPE_ROCK": 5, "TYPE_BUG": 6, "TYPE_GHOST": 7,
    "TYPE_STEEL": 8, "TYPE_MYSTERY": 9, "TYPE_FIRE": 10, "TYPE_WATER": 11,
    "TYPE_GRASS": 12, "TYPE_ELECTRIC": 13, "TYPE_PSYCHIC": 14, "TYPE_ICE": 15,
    "TYPE_DRAGON": 16, "TYPE_DARK": 17
}

EFFECT_MAP = {
    "TYPE_MUL_NO_EFFECT": 0.0,
    "TYPE_MUL_NOT_EFFECTIVE": 0.5,
    "TYPE_MUL_SUPER_EFFECTIVE": 2.0,
}

def main():
    path = os.path.join(POKE, "src", "battle_main.c")
    with open(path) as f:
        content = f.read()

    # Find the gTypeEffectiveness table
    m = re.search(r'const u8 gTypeEffectiveness\[\d+\]\s*=\s*\{([^;]+)\};', content, re.DOTALL)
    if not m:
        print("ERROR: Could not find gTypeEffectiveness table!")
        return

    table_content = m.group(1)

    # Build the effectiveness matrix
    # Default everything to 1.0 (neutral)
    valid_types = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17]
    matrix = {}
    for atk in valid_types:
        matrix[atk] = {}
        for dfn in valid_types:
            matrix[atk][dfn] = 1.0

    # Parse triplets: ATK_TYPE, DEF_TYPE, MULTIPLIER
    tokens = re.findall(r'(TYPE_\w+)', table_content)

    i = 0
    while i + 2 < len(tokens):
        atk_type = tokens[i]
        def_type = tokens[i + 1]
        mul_type = tokens[i + 2]
        i += 3

        # Skip special markers (FORESIGHT, ENDTABLE)
        if atk_type in ("TYPE_FORESIGHT", "TYPE_ENDTABLE"):
            continue
        if def_type in ("TYPE_FORESIGHT", "TYPE_ENDTABLE"):
            continue

        atk_id = TYPE_MAP.get(atk_type)
        def_id = TYPE_MAP.get(def_type)
        mul = EFFECT_MAP.get(mul_type)

        if atk_id is not None and def_id is not None and mul is not None:
            if atk_id in matrix and def_id in matrix.get(atk_id, {}):
                matrix[atk_id][def_id] = mul

    # Convert to serializable format
    output = {
        "type_names": {str(k): v for k, v in TYPE_NAMES.items()},
        "effectiveness": {}
    }

    for atk_id in valid_types:
        atk_name = TYPE_NAMES.get(atk_id, str(atk_id))
        output["effectiveness"][str(atk_id)] = {}
        for def_id in valid_types:
            output["effectiveness"][str(atk_id)][str(def_id)] = matrix[atk_id][def_id]

    # Write output
    out_dir = os.path.join(BASE, "assets", "data")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "type_chart.json")
    with open(out_path, "w") as f:
        json.dump(output, f, indent=2)

    # Print a nice summary
    print(f"Wrote type chart ({len(valid_types)}x{len(valid_types)} matrix) to {out_path}")

    # Count non-neutral entries
    non_neutral = sum(
        1 for atk in valid_types for dfn in valid_types
        if matrix[atk][dfn] != 1.0
    )
    print(f"  {non_neutral} non-neutral matchups found")

if __name__ == "__main__":
    main()

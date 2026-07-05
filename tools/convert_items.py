#!/usr/bin/env python3
"""
Converts pokeemerald item data into a Godot-friendly JSON file.
Parses: items.h (data), items.h (constants)
"""
import re
import json
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POKE = os.path.join(BASE, "_unused_assets", "pokeemerald-master")

def parse_item_ids():
    """Parse ITEM_X → ID mapping from constants."""
    path = os.path.join(POKE, "include", "constants", "items.h")
    items = {}
    with open(path) as f:
        for line in f:
            m = re.match(r"#define\s+(ITEM_\w+)\s+(\d+)", line)
            if m:
                items[m.group(1)] = int(m.group(2))
    return items

def parse_item_data(item_ids):
    """Parse item definitions from src/data/items.h."""
    path = os.path.join(POKE, "src", "data", "items.h")
    with open(path) as f:
        content = f.read()

    items = {}
    # Match each item block
    pattern = r'\[(ITEM_\w+)\]\s*=\s*\{([^}]+)\}'
    for m in re.finditer(pattern, content):
        item_name = m.group(1)
        block = m.group(2)

        if item_name not in item_ids:
            continue

        item_id = item_ids[item_name]

        data = {
            "id": item_id,
            "internal_name": item_name,
        }

        # Parse name
        nm = re.search(r'\.name\s*=\s*_\("([^"]+)"\)', block)
        data["name"] = nm.group(1).title() if nm else item_name.replace("ITEM_", "").replace("_", " ").title()

        # Parse price
        pm = re.search(r'\.price\s*=\s*(\d+)', block)
        data["price"] = int(pm.group(1)) if pm else 0

        # Parse pocket
        pocket_m = re.search(r'\.pocket\s*=\s*(\w+)', block)
        if pocket_m:
            pocket_map = {
                "POCKET_ITEMS": "items",
                "POCKET_POKE_BALLS": "poke_balls",
                "POCKET_TM_HM": "tm_hm",
                "POCKET_BERRIES": "berries",
                "POCKET_KEY_ITEMS": "key_items",
            }
            data["pocket"] = pocket_map.get(pocket_m.group(1), "items")

        # Parse battle usage
        battle_m = re.search(r'\.battleUsage\s*=\s*(\w+)', block)
        data["battle_usable"] = battle_m is not None

        items[str(item_id)] = data

    return items

def main():
    print("Parsing item IDs...")
    item_ids = parse_item_ids()
    print(f"  Found {len(item_ids)} item definitions")

    print("Parsing item data...")
    items = parse_item_data(item_ids)
    print(f"  Parsed {len(items)} items")

    # Write output
    out_dir = os.path.join(BASE, "assets", "data")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "items.json")
    with open(out_path, "w") as f:
        json.dump(items, f, indent=2)

    print(f"\nWrote {len(items)} items to {out_path}")

if __name__ == "__main__":
    main()

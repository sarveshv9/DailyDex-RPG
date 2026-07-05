#!/usr/bin/env python3
"""
Converts pokeemerald wild encounter data into a simplified Godot-friendly JSON.
The pokeemerald data is already in JSON format, so this just simplifies it.
"""
import json
import os
import re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POKE = os.path.join(BASE, "_unused_assets", "pokeemerald-master")

# Map SPECIES_X to numeric IDs
def parse_species_ids():
    path = os.path.join(POKE, "include", "constants", "species.h")
    ids = {}
    with open(path) as f:
        for line in f:
            m = re.match(r"#define\s+(SPECIES_\w+)\s+(\d+)", line)
            if m and "OLD_UNOWN" not in m.group(1) and "UNOWN_" not in m.group(1):
                ids[m.group(1)] = int(m.group(2))
    return ids

def main():
    print("Parsing wild encounters...")
    path = os.path.join(POKE, "src", "data", "wild_encounters.json")
    with open(path) as f:
        raw = json.load(f)

    species_ids = parse_species_ids()

    # Extract the main encounter group (for_maps = true)
    main_group = None
    for group in raw.get("wild_encounter_groups", []):
        if group.get("for_maps"):
            main_group = group
            break

    if not main_group:
        print("ERROR: No map encounter group found!")
        return

    # Get encounter rates per slot
    land_rates = []
    water_rates = []
    for field in main_group.get("fields", []):
        if field["type"] == "land_mons":
            land_rates = field["encounter_rates"]
        elif field["type"] == "water_mons":
            water_rates = field["encounter_rates"]

    output = {}
    for encounter in main_group.get("encounters", []):
        map_name = encounter["map"]  # e.g. "MAP_ROUTE101"
        entry = {"map": map_name}

        # Land encounters
        if "land_mons" in encounter:
            land_data = encounter["land_mons"]
            land_mons = []
            for i, mon in enumerate(land_data.get("mons", [])):
                species = mon["species"]
                species_id = species_ids.get(species, 0)
                rate = land_rates[i] if i < len(land_rates) else 1
                land_mons.append({
                    "species_id": species_id,
                    "species_name": species.replace("SPECIES_", "").title(),
                    "min_level": mon["min_level"],
                    "max_level": mon["max_level"],
                    "rate": rate
                })
            entry["land_mons"] = {
                "encounter_rate": land_data.get("encounter_rate", 20),
                "mons": land_mons
            }

        # Water encounters
        if "water_mons" in encounter:
            water_data = encounter["water_mons"]
            water_mons = []
            for i, mon in enumerate(water_data.get("mons", [])):
                species = mon["species"]
                species_id = species_ids.get(species, 0)
                rate = water_rates[i] if i < len(water_rates) else 1
                water_mons.append({
                    "species_id": species_id,
                    "species_name": species.replace("SPECIES_", "").title(),
                    "min_level": mon["min_level"],
                    "max_level": mon["max_level"],
                    "rate": rate
                })
            entry["water_mons"] = {
                "encounter_rate": water_data.get("encounter_rate", 5),
                "mons": water_mons
            }

        output[map_name] = entry

    # Write output
    out_dir = os.path.join(BASE, "assets", "data")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "wild_encounters.json")
    with open(out_path, "w") as f:
        json.dump(output, f, indent=2)

    print(f"Wrote {len(output)} map encounter tables to {out_path}")

if __name__ == "__main__":
    main()

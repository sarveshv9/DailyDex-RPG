#!/usr/bin/env python3
"""
Converts pokeemerald species data into a Godot-friendly JSON file.
Parses: species_info.h, species_names.h, evolution.h, level_up_learnsets.h,
        species.h, abilities.h, pokemon.h (constants)
"""
import re
import json
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POKE = os.path.join(BASE, "_unused_assets", "pokeemerald-master")

# ── Parse species.h to get ID→name mapping ──────────────────────────
def parse_species_ids():
    path = os.path.join(POKE, "include", "constants", "species.h")
    ids = {}
    with open(path) as f:
        for line in f:
            m = re.match(r"#define\s+(SPECIES_\w+)\s+(\d+)", line)
            if m and "OLD_UNOWN" not in m.group(1) and "UNOWN_" not in m.group(1):
                name = m.group(1)
                val = int(m.group(2))
                if val > 0 and val <= 411:  # NUM_SPECIES = 412 (EGG), we want 1-411
                    ids[name] = val
    return ids

# ── Parse abilities.h ────────────────────────────────────────────────
def parse_abilities():
    path = os.path.join(POKE, "include", "constants", "abilities.h")
    abilities = {}
    with open(path) as f:
        for line in f:
            m = re.match(r"#define\s+(ABILITY_\w+)\s+(\d+)", line)
            if m and m.group(1) != "ABILITIES_COUNT":
                abilities[int(m.group(2))] = m.group(1).replace("ABILITY_", "").replace("_", " ").title()
    return abilities

# ── Parse type constants ─────────────────────────────────────────────
def parse_types():
    path = os.path.join(POKE, "include", "constants", "pokemon.h")
    types = {}
    with open(path) as f:
        for line in f:
            m = re.match(r"#define\s+TYPE_(\w+)\s+(\d+)", line)
            if m and m.group(1) not in ("NONE", "MYSTERY"):
                types[f"TYPE_{m.group(1)}"] = int(m.group(2))
    return types

TYPE_NAMES = {
    0: "Normal", 1: "Fighting", 2: "Flying", 3: "Poison", 4: "Ground",
    5: "Rock", 6: "Bug", 7: "Ghost", 8: "Steel", 9: "Mystery",
    10: "Fire", 11: "Water", 12: "Grass", 13: "Electric", 14: "Psychic",
    15: "Ice", 16: "Dragon", 17: "Dark"
}

GROWTH_NAMES = {
    0: "Medium Fast", 1: "Erratic", 2: "Fluctuating",
    3: "Medium Slow", 4: "Fast", 5: "Slow"
}

# ── Parse species_names.h ────────────────────────────────────────────
def parse_species_names():
    path = os.path.join(POKE, "src", "data", "text", "species_names.h")
    names = {}
    with open(path) as f:
        for line in f:
            m = re.match(r'\s*\[(SPECIES_\w+)\]\s*=\s*_\("([^"]+)"\)', line)
            if m:
                names[m.group(1)] = m.group(2).title()
    return names

# ── Parse species_info.h ─────────────────────────────────────────────
def parse_species_info(species_ids):
    path = os.path.join(POKE, "src", "data", "pokemon", "species_info.h")
    with open(path) as f:
        content = f.read()

    species_data = {}

    # Use brace-counting to extract each species block properly
    # Find all [SPECIES_X] = { ... } blocks handling nested braces
    for m in re.finditer(r'\[(SPECIES_\w+)\]\s*=\s*\{', content):
        sp_name = m.group(1)
        if sp_name not in species_ids:
            continue

        # Find the matching closing brace using brace counting
        start = m.end()
        depth = 1
        pos = start
        while pos < len(content) and depth > 0:
            if content[pos] == '{':
                depth += 1
            elif content[pos] == '}':
                depth -= 1
            pos += 1
        block = content[start:pos - 1]

        data = {}
        # Parse simple numeric fields
        for field, key in [
            ("baseHP", "base_hp"), ("baseAttack", "base_attack"),
            ("baseDefense", "base_defense"), ("baseSpeed", "base_speed"),
            ("baseSpAttack", "base_sp_attack"), ("baseSpDefense", "base_sp_defense"),
            ("catchRate", "catch_rate"), ("expYield", "exp_yield"),
            ("friendship", "friendship"),
        ]:
            fm = re.search(rf'\.{field}\s*=\s*(\d+)', block)
            if fm:
                data[key] = int(fm.group(1))

        # friendship might be STANDARD_FRIENDSHIP
        fm = re.search(r'\.friendship\s*=\s*STANDARD_FRIENDSHIP', block)
        if fm:
            data["friendship"] = 70

        # Parse types
        tm = re.search(r'\.types\s*=\s*\{\s*(TYPE_\w+)\s*,\s*(TYPE_\w+)\s*\}', block)
        if tm:
            t1_name = tm.group(1).replace("TYPE_", "")
            t2_name = tm.group(2).replace("TYPE_", "")
            # Convert to type IDs
            type_map = {
                "NORMAL": 0, "FIGHTING": 1, "FLYING": 2, "POISON": 3, "GROUND": 4,
                "ROCK": 5, "BUG": 6, "GHOST": 7, "STEEL": 8, "MYSTERY": 9,
                "FIRE": 10, "WATER": 11, "GRASS": 12, "ELECTRIC": 13, "PSYCHIC": 14,
                "ICE": 15, "DRAGON": 16, "DARK": 17
            }
            data["type1"] = type_map.get(t1_name, 0)
            data["type2"] = type_map.get(t2_name, 0)

        # Parse abilities
        am = re.search(r'\.abilities\s*=\s*\{(ABILITY_\w+)\s*,\s*(ABILITY_\w+)\}', block)
        if am:
            data["ability1"] = am.group(1).replace("ABILITY_", "").replace("_", " ").title()
            data["ability2"] = am.group(2).replace("ABILITY_", "").replace("_", " ").title()

        # Parse growth rate
        gm = re.search(r'\.growthRate\s*=\s*GROWTH_(\w+)', block)
        if gm:
            gr_map = {"MEDIUM_FAST": 0, "ERRATIC": 1, "FLUCTUATING": 2,
                       "MEDIUM_SLOW": 3, "FAST": 4, "SLOW": 5}
            data["growth_rate"] = gr_map.get(gm.group(1), 0)

        # Parse gender ratio
        gender_m = re.search(r'\.genderRatio\s*=\s*(?:PERCENT_FEMALE\(([^)]+)\)|MON_GENDERLESS|MON_MALE|MON_FEMALE)', block)
        if gender_m:
            raw = block[gender_m.start():gender_m.end()]
            if "MON_GENDERLESS" in raw:
                data["gender_ratio"] = -1  # genderless
            elif "MON_MALE" in raw:
                data["gender_ratio"] = 0
            elif "MON_FEMALE" in raw:
                data["gender_ratio"] = 254
            elif gender_m.group(1):
                data["gender_ratio"] = float(gender_m.group(1))

        species_data[sp_name] = data
    return species_data

# ── Parse evolution.h ────────────────────────────────────────────────
def parse_evolutions(species_ids):
    path = os.path.join(POKE, "src", "data", "pokemon", "evolution.h")
    with open(path) as f:
        content = f.read()

    evolutions = {}
    # Match lines like: [SPECIES_BULBASAUR] = {{EVO_LEVEL, 16, SPECIES_IVYSAUR}},
    for line in content.split('\n'):
        m = re.match(r'\s*\[(SPECIES_\w+)\]\s*=\s*\{(.+)\}', line)
        if not m:
            continue
        sp = m.group(1)
        if sp not in species_ids:
            continue
        evos_str = m.group(2)
        evos = []
        for em in re.finditer(r'\{(\w+)\s*,\s*(\w+)\s*,\s*(SPECIES_\w+)\}', evos_str):
            method = em.group(1)
            param = em.group(2)
            target = em.group(3)
            # Try to parse param as int
            try:
                param_val = int(param)
            except ValueError:
                param_val = param  # Keep as string (e.g., ITEM_THUNDER_STONE)

            evos.append({
                "method": method,
                "param": param_val,
                "target": species_ids.get(target, 0)
            })
        if evos:
            evolutions[sp] = evos
    return evolutions

# ── Parse level_up_learnsets.h ───────────────────────────────────────
def parse_learnsets():
    path = os.path.join(POKE, "src", "data", "pokemon", "level_up_learnsets.h")
    with open(path) as f:
        content = f.read()

    # Parse move name → ID mapping
    moves_path = os.path.join(POKE, "include", "constants", "moves.h")
    move_ids = {}
    with open(moves_path) as f:
        for line in f:
            m = re.match(r"#define\s+(MOVE_\w+)\s+(\d+)", line)
            if m and m.group(1) != "MOVES_COUNT":
                move_ids[m.group(1)] = int(m.group(2))

    learnsets = {}
    # Match each learnset array
    pattern = r'static const u16 s(\w+)LevelUpLearnset\[\]\s*=\s*\{([^;]+)\};'
    for m in re.finditer(pattern, content):
        pokemon_name = m.group(1)  # e.g., "Bulbasaur"
        entries_str = m.group(2)

        moves = []
        for em in re.finditer(r'LEVEL_UP_MOVE\(\s*(\d+)\s*,\s*(MOVE_\w+)\s*\)', entries_str):
            level = int(em.group(1))
            move_name = em.group(2)
            move_id = move_ids.get(move_name, 0)
            moves.append({"level": level, "move_id": move_id})

        # Convert pokemon_name to SPECIES_ format
        # CamelCase to UPPER_SNAKE: "Bulbasaur" → "BULBASAUR", "MrMime" → "MR_MIME"
        # We'll just store by lowercase name and match later
        learnsets[pokemon_name.lower()] = moves

    return learnsets

# ── Map species name to learnset key ─────────────────────────────────
def species_to_learnset_key(species_name):
    """Convert SPECIES_BULBASAUR to 'bulbasaur'"""
    key = species_name.replace("SPECIES_", "").lower()
    # Handle special cases
    key_map = {
        "nidoran_f": "nidoranf",
        "nidoran_m": "nidoranm",
        "mr_mime": "mrmime",
        "ho_oh": "hooh",
    }
    return key_map.get(key, key)

# ── Main ─────────────────────────────────────────────────────────────
def main():
    print("Parsing species IDs...")
    species_ids = parse_species_ids()
    print(f"  Found {len(species_ids)} species")

    print("Parsing abilities...")
    abilities = parse_abilities()

    print("Parsing species names...")
    species_names = parse_species_names()

    print("Parsing species info (base stats)...")
    species_info = parse_species_info(species_ids)

    print("Parsing evolutions...")
    evolutions = parse_evolutions(species_ids)

    print("Parsing level-up learnsets...")
    learnsets = parse_learnsets()

    # Assemble final output
    output = {}
    for sp_name, sp_id in sorted(species_ids.items(), key=lambda x: x[1]):
        entry = {
            "id": sp_id,
            "name": species_names.get(sp_name, sp_name.replace("SPECIES_", "").title()),
            "internal_name": sp_name,
        }

        # Add base stats from species_info
        info = species_info.get(sp_name, {})
        entry.update({
            "base_hp": info.get("base_hp", 50),
            "base_attack": info.get("base_attack", 50),
            "base_defense": info.get("base_defense", 50),
            "base_speed": info.get("base_speed", 50),
            "base_sp_attack": info.get("base_sp_attack", 50),
            "base_sp_defense": info.get("base_sp_defense", 50),
            "type1": info.get("type1", 0),
            "type2": info.get("type2", 0),
            "catch_rate": info.get("catch_rate", 45),
            "exp_yield": info.get("exp_yield", 64),
            "growth_rate": info.get("growth_rate", 0),
            "gender_ratio": info.get("gender_ratio", 50.0),
            "ability1": info.get("ability1", "None"),
            "ability2": info.get("ability2", "None"),
        })

        # Add evolution data
        if sp_name in evolutions:
            entry["evolutions"] = evolutions[sp_name]

        # Add learnset
        ls_key = species_to_learnset_key(sp_name)
        if ls_key in learnsets:
            entry["learnset"] = learnsets[ls_key]

        output[str(sp_id)] = entry

    # Write output
    out_dir = os.path.join(BASE, "assets", "data")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "species.json")
    with open(out_path, "w") as f:
        json.dump(output, f, indent=2)

    print(f"\nWrote {len(output)} species to {out_path}")

if __name__ == "__main__":
    main()

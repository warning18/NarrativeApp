#!/usr/bin/env python3
"""Apply docs/narrative/drafts/p3-beat2-patch.json to the story DAG (idempotent).

Run from the repo root: python3 docs/narrative/drafts/apply_p3_beat2.py
Then run `dart format lib/data/world_map.dart` (the map edit lists long lines).
Adds the eight beat2_<companion> scenes, Vica's two scenes (loyal_vica, beat2_vica) and three callbacks on 1200, the
<companion>_loyal_done flag on the eight loyal_* choices, and the
"Sit with ..." hub choices on 7516_eve. Needs 7516_eve to exist.
"""
import json, sys, pathlib
root = pathlib.Path(__file__).resolve().parents[3]
dag_path = root / "assets/Cleaned_Narrative_DAG.json"
patch = json.loads((root / "docs/narrative/drafts/p3-beat2-patch.json").read_text(encoding="utf-8"))
raw = dag_path.read_text(encoding="utf-8")
dag = json.loads(raw)
nodes = dag["nodes"] if isinstance(dag.get("nodes"), dict) else dag
if "7516_eve" not in nodes:
    sys.exit("7516_eve is not in the DAG yet: merge the chapter 7 wiring first.")
for nid, node in patch["nodes"].items():
    nodes[nid] = node
for e in patch["edits"]:
    n = nodes[e["node"]]
    for c in n["choices"]:
        if "add_flag_to_all_choices" in e:
            f = c.setdefault("flagsToAdd", [])
            if e["add_flag_to_all_choices"] not in f:
                f.append(e["add_flag_to_all_choices"])
        if "set_all_next" in e:
            c["next_id"] = e["set_all_next"]
for cb in patch.get("callbacks_add", []):
    n = nodes[cb["node"]]
    have_flags = {c["flag"] for c in n.setdefault("flag_callbacks", [])}
    for item in cb["items"]:
        if item["flag"] not in have_flags:
            n["flag_callbacks"].append(item)
hub = nodes[patch["hub"]["node"]]
have = {c.get("next_id") for c in hub["choices"]}
new = [c for c in patch["hub"]["insert_before_last_choice"] if c["next_id"] not in have]
hub["choices"][-1:-1] = new
indent = 2 if raw.startswith("{\n  ") else 4 if raw.startswith("{\n    ") else None
dag_path.write_text(json.dumps(dag, ensure_ascii=False, indent=indent) + ("\n" if raw.endswith("\n") else ""), encoding="utf-8")
# The map lists every scene at a place (world_map_test): three one-line edits.
wm = root / "lib/data/world_map.dart"
src = wm.read_text(encoding="utf-8")
def add_after(src, anchor, extra):
    if extra in src:
        return src
    assert src.count(anchor) == 1, anchor
    return src.replace(anchor, anchor + extra)
beats = "".join(f" 'beat2_{c}'," for c in ["kelda","sable","maren","liora","vess","grosh","tobin","malrik","vica"])
src = add_after(src, "'loyal_kelda',", " 'loyal_vica',")
src = add_after(src, "'7515_rest', '7516_eve', '7517_stair',", beats)
wm.write_text(src, encoding="utf-8")
print("nodes added/updated:", len(patch["nodes"]), "hub choices added:", len(new))

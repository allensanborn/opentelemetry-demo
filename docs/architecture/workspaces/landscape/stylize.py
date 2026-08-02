#!/usr/bin/env python3
"""Post-process a generated system-landscape workspace: inject the shared styles
and add two landscape views (a clean business view with the Platform excluded, and
a full view). `generate system-landscape` produces only the merged model — no views
and no styles — so this adds them. Input/output are Structurizr workspace JSON.

Usage: stylize.py <generated.json> <output.json>
"""
import json
import sys

STYLES = {
    "elements": [
        # base styles (the generated workspace has no theme) — override for tagged elements below
        {"tag": "Software System", "background": "#1168bd", "color": "#ffffff"},
        {"tag": "Person", "background": "#08427b", "color": "#ffffff", "shape": "Person"},
        {"tag": "External", "background": "#8a8a8a", "color": "#ffffff", "border": "Dashed"},
        {"tag": "Platform", "background": "#667085", "color": "#ffffff"},
        {"tag": "Database", "shape": "Cylinder"},
        {"tag": "Queue", "shape": "Pipe"},
    ],
    "relationships": [
        {"tag": "Telemetry", "color": "#7a7a7a", "dashed": True},
        {"tag": "FeatureFlag", "color": "#7a7a7a", "dashed": True},
    ],
}
AUTOLAYOUT = {"edgeSeparation": 50, "nodeSeparation": 50,
              "rankDirection": "LeftRight", "rankSeparation": 100, "vertices": False}


def main(src, dst):
    w = json.load(open(src))
    m = w["model"]

    systems = m.get("softwareSystems", [])
    people = m.get("people", [])
    platform_ids = {s["id"] for s in systems if "Platform" in (s.get("tags", "").split(","))}
    system_ids = {s["id"] for s in systems}
    person_ids = {p["id"] for p in people}

    # relationships are nested under their source element
    rels = []
    for el in systems + people:
        for r in el.get("relationships", []):
            rels.append(r)

    def view(key, name, desc, keep_ids):
        rel_ids = [r["id"] for r in rels
                   if r["sourceId"] in keep_ids and r["destinationId"] in keep_ids]
        return {
            "key": key, "name": name, "description": desc, "order": 1,
            "elements": [{"id": i, "x": 0, "y": 0} for i in sorted(keep_ids)],
            "relationships": [{"id": i} for i in rel_ids],
            "automaticLayout": AUTOLAYOUT,
            "enterpriseBoundaryVisible": True,
        }

    business_ids = (system_ids - platform_ids) | person_ids
    all_ids = system_ids | person_ids

    w.setdefault("views", {})
    w["views"]["systemLandscapeViews"] = [
        view("Landscape", "System Landscape",
             "Generated from the per-system workspaces. Platform excluded for legibility.",
             business_ids),
        {**view("PlatformLandscape", "System Landscape (with Platform)",
                "Full generated landscape including the shared Platform systems.",
                all_ids), "order": 2},
    ]
    w["views"].setdefault("configuration", {})["styles"] = STYLES

    json.dump(w, open(dst, "w"), indent=2)
    print(f"stylized: {len(business_ids)} business elements, "
          f"{len(all_ids)} total, {len(rels)} relationships -> {dst}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])

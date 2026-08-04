# Astronomy Shop — Enterprise C4 (one workspace per system)

This is the **decentralized / enterprise** way to model the shop, per Structurizr's own
guidance: **one software system per workspace**, each owned by a team, all sharing a common
**system catalog**, with a separate **landscape** workspace on top.

> Compare with [`../`](../), which models the *same* architecture as a single team-aligned
> landscape workspace. That single-workspace approach is Structurizr's `unscoped` scope —
> fine for one repo, but the docs recommend this decentralized structure once multiple teams
> own multiple systems. This directory demonstrates that structure.

## Why this structure

From the Structurizr docs:
- "*A workspace should contain the model, views, documentation, and decisions for a single
  software system.*" and "*Don't model every software system in a single workspace.*"
  ([recommendations](https://docs.structurizr.com/workspaces/recommendations))
- Scopes are **softwareSystem** / **landscape** / **unscoped**; merging many systems into one
  unscoped workspace is allowed but "*the end-result will be cluttered.*"
  ([scope](https://docs.structurizr.com/workspaces/scope))
- For many systems / many teams, keep each system's workspace in its **own team's repo**,
  extending a shared **system catalog** that holds *only* the software-system definitions
  ("*the internal details ... should be omitted*"), then **generate** the landscape by merging
  them. ([enterprise](https://docs.structurizr.com/workspaces/enterprise))

## Layout

```
workspaces/
├── system-catalog/        the shared catalog: every software system, definitions only
├── _shared/styles.dsl     one styles block, !included by every workspace
├── storefront/            ┐
├── shopping-assistant/    │  one workspace PER SYSTEM. Each `extends` the catalog,
├── checkout-orders/       │  adds its own containers, and declares the relationships
├── cart/                  │  it originates (to other systems + to the platform).
├── product-catalog/       │  Views: a System Context + a Container view.
├── shipping/              │
├── recommendations/       │
├── ads/ · payments/       │
├── notifications/         │
├── currency/              │
├── feature-flags/         │  ← platform systems get their own workspace too
├── observability-platform/┘
└── landscape/             the system landscape — GENERATED, not hand-authored:
    ├── generate-landscape.sh    the pipeline (generate → stylize → render)
    ├── stylize.py               post-processor (adds styles + views)
    ├── workspace.json           the generated, styled landscape
    └── exports/                 rendered PNG/SVG
```

Each `<system>/workspace.dsl` starts with `workspace extends ../system-catalog/workspace.dsl`,
references other systems by their catalog identifier, and `!include`s the shared styles. Images
are in each `<system>/exports/`.

## Generating the landscape (no server, no license)

The landscape is **generated from the per-system workspaces** — the whole point of the
decentralized model. `./landscape/generate-landscape.sh` runs the pipeline:

```
structurizr generate system-landscape   merges the per-system models and DERIVES the
   -i <workspaces> -o _generated.json    system→system edges from each team's container
                                         relationships (needs !impliedRelationships true
                                         in each workspace so container→system rolls up)
  → stylize.py                           the generated model has no views/styles; this
                                         injects the shared styles + a clean landscape
                                         view (Platform excluded) and a full one
  → structurizr export + plantuml        render PNG/SVG
```

Re-run it whenever a team's workspace changes; the landscape edges are never hand-maintained.

**What needs a licensed server vs. what doesn't:** `generate`, `export`, `merge`, `validate`,
`inspect` are **local CLI commands** — no server, no license. Only the *hosted collaboration*
features — `server` (the on-premises UI/API), and `create`/`push`/`pull` against it — require a
**commercial Structurizr license** (the `server` container exits with "No license found"
otherwise). So a team publishing each workspace to a shared server and pulling a live landscape
is the licensed path; the **local generate pipeline above reproduces the same landscape offline**.

## How it maps to the real Structurizr enterprise workflow

| Real (licensed-server) enterprise setup | What we do here (local, license-free) |
|---|---|
| Each team's workspace lives in its **own repo**, `push`ed to a Structurizr server | All workspaces live in this one folder (it's a demo) |
| System catalog published at a stable **HTTPS URL**, workspaces `extends` the URL | Workspaces `extends` the catalog by **relative path** |
| Landscape built by `pull` all workspaces → `generate system-landscape` → `push` | Same `generate system-landscape`, but run **directly on the local files** (`-i`/`-o`) — see the pipeline above |
| Cross-cutting fan-in (every system → the platform) aggregated automatically | Each system declares its **own** platform edge; `generate` aggregates them; the clean view excludes the platform |

## Rendering / browsing

Each workspace is independent. Headless export (from `workspaces/`):

```bash
docker run --rm -v "$PWD:/work" -w /work structurizr/structurizr \
  export -workspace checkout-orders/workspace.dsl -format plantuml -output checkout-orders/exports
docker run --rm -v "$PWD/checkout-orders/exports:/data" -w /data plantuml/plantuml -tpng "structurizr-*.puml"
```

Browse one interactively (the local server serves a single workspace dir):

```bash
docker run --rm -p 8080:8080 \
  -v "$(pwd)/docs/architecture/workspaces/checkout-orders:/usr/local/structurizr" \
  structurizr/structurizr local
```

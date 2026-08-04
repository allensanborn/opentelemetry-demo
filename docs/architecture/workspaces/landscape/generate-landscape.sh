#!/usr/bin/env bash
# Generate the system landscape from the per-system workspaces — no server, no license.
#
#   structurizr generate system-landscape   (merges the per-system models, deriving
#                                             system->system edges from each team's
#                                             container relationships)
#     -> stylize.py                          (inject styles + a clean/full landscape view)
#     -> structurizr export + plantuml       (render PNG/SVG)
#
# Run from the workspaces/ directory:  ./landscape/generate-landscape.sh
set -euo pipefail
cd "$(dirname "$0")/.."                      # -> workspaces/
ROOT="$(pwd)"

echo "==> generate system-landscape (from */workspace.dsl)"
docker run --rm -v "$ROOT:/work" -w /work structurizr/structurizr \
  generate system-landscape -i /work -o /work/landscape/_generated.json \
  -exclude 'workspace\.json' -relationships first

echo "==> stylize (add styles + views)"
python3 landscape/stylize.py landscape/_generated.json landscape/workspace.json
rm -f landscape/_generated.json

echo "==> export + render"
rm -f landscape/exports/*.puml landscape/exports/*.png landscape/exports/*.svg 2>/dev/null || true
docker run --rm -v "$ROOT:/work" -w /work structurizr/structurizr \
  export -workspace landscape/workspace.json -format plantuml -output landscape/exports
( cd landscape/exports \
  && docker run --rm -v "$PWD:/data" -w /data plantuml/plantuml -tpng "structurizr-*.puml" \
  && docker run --rm -v "$PWD:/data" -w /data plantuml/plantuml -tsvg "structurizr-*.puml" )

echo "==> done: landscape/workspace.json + landscape/exports/"

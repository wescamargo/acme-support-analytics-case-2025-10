#!/usr/bin/env bash
set -euo pipefail
dirs=(
  data data/outputs
  models/staging models/intermediate models/marts
  analyses reports scripts tests
)
for d in "${dirs[@]}"; do
  mkdir -p "$d"
  : > "$d/.gitkeep"
done
echo "Folders created."

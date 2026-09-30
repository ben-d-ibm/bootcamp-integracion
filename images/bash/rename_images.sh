#!/bin/bash

# Script to rename beetech_*.png files sorted by creation date
# Output format: image_bootcamp_XX.png

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "Reading metadata and sorting by creation date..."

# Build a list of "timestamp filename" pairs using macOS mdls
declare -a pairs=()

for f in beetech_*.png; do
  # kMDItemContentCreationDate returns format: 2024-01-15 10:30:00 +0000
  ts=$(mdls -name kMDItemContentCreationDate -raw "$f" 2>/dev/null)

  if [[ -z "$ts" || "$ts" == "(null)" ]]; then
    # Fallback to file birth time via stat
    ts=$(stat -f "%SB" -t "%Y%m%d%H%M%S" "$f" 2>/dev/null)
  else
    # Normalize to sortable string: remove spaces and colon separators
    ts=$(echo "$ts" | sed 's/[: +-]//g' | cut -c1-14)
  fi

  pairs+=("${ts}|${f}")
done

# Sort by timestamp (first field)
IFS=$'\n' sorted=($(printf '%s\n' "${pairs[@]}" | sort -t'|' -k1,1))
unset IFS

echo ""
echo "Rename plan (dry-run first — set DRY_RUN=0 to apply):"
echo "-------------------------------------------------------"

counter=1
for entry in "${sorted[@]}"; do
  ts="${entry%%|*}"
  original="${entry##*|}"
  new_name=$(printf "image_bootcamp_%02d.png" "$counter")

  echo "  [$ts]  $original  ->  $new_name"

  if [[ "${DRY_RUN:-1}" == "0" ]]; then
    mv "$original" "$new_name"
  fi

  ((counter++))
done

if [[ "${DRY_RUN:-1}" != "0" ]]; then
  echo ""
  echo "Dry-run complete. To apply renames, run:"
  echo "  DRY_RUN=0 bash rename_images.sh"
fi

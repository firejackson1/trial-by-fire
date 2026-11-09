#!/usr/bin/env bash
# Copy the Trial by Fire device tree into a LineageOS 24.0 tree and apply one patch per project.
# Usage: apply-patches.sh /path/to/lineage-24.0
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
TOP="${1:?usage: apply-patches.sh /path/to/lineage-24.0}"
[ -f "$TOP/build/envsetup.sh" ] || { echo "not a LineageOS tree: $TOP" >&2; exit 2; }

# Refuse to mix with existing local changes.
while IFS= read -r p; do
  if [ -n "$(git -C "$TOP/$p" status --porcelain)" ]; then
    echo "refusing: $p already has local changes" >&2; exit 3
  fi
done < <(cd "$REPO/patches" && find . -name '*.patch' -printf '%h\n' | sed 's#^\./##' | sort -u)

mkdir -p "$TOP/device/amazon"
rsync -a "$REPO/device/amazon/trona-compat/" "$TOP/device/amazon/trona-compat/"
echo "device tree: device/amazon/trona-compat"

cd "$REPO/patches"
find . -name '*.patch' | sort | while IFS= read -r patch; do
  project="$(dirname "${patch#./}")"
  git -C "$TOP/$project" apply --index --whitespace=nowarn "$REPO/patches/${patch#./}"
  echo "applied: $project"
done
echo "done. Next: scripts/extract-camera-fix.sh"

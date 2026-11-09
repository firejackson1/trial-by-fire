#!/usr/bin/env bash
# Turn the built system.img into an exact image of the tablet's system partition.
# Usage: make-partition-image.sh /path/to/lineage-24.0 output.img
set -euo pipefail
TOP="${1:?usage: make-partition-image.sh /path/to/lineage-24.0 output.img}"; OUT="${2:?output.img}"
PART_SIZE=3808428032   # trona system partition (mmcblk0p19)
SRC="$TOP/out/target/product/generic_arm64/system.img"
AVB="$TOP/out/host/linux-x86/bin/avbtool"
cp "$SRC" "$OUT"
e2fsck -fn "$OUT" >/dev/null
"$AVB" resize_image --image "$OUT" --partition_size "$PART_SIZE"
"$AVB" verify_image --image "$OUT"
[ "$(stat -c %s "$OUT")" -eq "$PART_SIZE" ] || { echo "wrong size" >&2; exit 3; }
sha256sum "$OUT"

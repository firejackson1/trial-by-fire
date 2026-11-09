#!/usr/bin/env bash
# Rebuild the one-byte camera library fix from YOUR tablet's stock vendor partition.
# The vendor's built-in DEFAULT_STEREO_SETTING JSON in libcameracustom.so has a trailing comma
# at file offset 0x5b193; this replaces that ',' with a space. Nothing proprietary is shipped
# in this repository. Usage: ADB_SERIAL=<serial> extract-camera-fix.sh /path/to/lineage-24.0
set -euo pipefail
TOP="${1:?usage: extract-camera-fix.sh /path/to/lineage-24.0}"
ADB="${ADB:-adb}"; SER=(); [ -n "${ADB_SERIAL:-}" ] && SER=(-s "$ADB_SERIAL")
STOCK_SHA=a38bbcfd191e2828d694ec62164a12a2e4e243ea772adb8b8ff02bfd6bc76443
FIXED_SHA=834ab4935e53e0484120311abb7eb80c59b1272e16cb86dc12597bbb6f04e910
OFFSET=$((0x5b193))
OUT="$TOP/device/amazon/trona-compat/camera/libcameracustom.trona-json-fix.bin"
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT

# The running ROM bind-mounts the fixed copy over /vendor, so read the vendor original
# from the vendor block device's filesystem when possible, else from /vendor (stock / TWRP).
"$ADB" "${SER[@]}" pull /vendor/lib64/libcameracustom.so "$tmp" >/dev/null
have="$(sha256sum "$tmp" | cut -d' ' -f1)"
if [ "$have" = "$FIXED_SHA" ]; then
  echo "device already serves the fixed library; using it as is"; mkdir -p "$(dirname "$OUT")"; cp "$tmp" "$OUT"; exit 0
fi
[ "$have" = "$STOCK_SHA" ] || { echo "unknown libcameracustom.so ($have); not patching" >&2; exit 4; }
[ "$(dd if="$tmp" bs=1 skip=$OFFSET count=1 status=none)" = "," ] || { echo "byte at 0x5b193 is not ','" >&2; exit 5; }
printf ' ' | dd of="$tmp" bs=1 seek=$OFFSET conv=notrunc status=none
[ "$(sha256sum "$tmp" | cut -d' ' -f1)" = "$FIXED_SHA" ] || { echo "result hash mismatch" >&2; exit 6; }
mkdir -p "$(dirname "$OUT")"; cp "$tmp" "$OUT"
echo "wrote $OUT ($FIXED_SHA)"

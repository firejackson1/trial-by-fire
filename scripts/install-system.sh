#!/usr/bin/env bash
# Write a Trial by Fire system partition image from TWRP, then verify by full read-back.
# Does NOT reboot. Usage: ADB_SERIAL=<serial> install-system.sh partition.img
set -uo pipefail
IMG="${1:?usage: install-system.sh partition.img}"
ADB="${ADB:-adb}"; SER=(); [ -n "${ADB_SERIAL:-}" ] && SER=(-s "$ADB_SERIAL")
a() { "$ADB" "${SER[@]}" "$@"; }
P=/dev/block/mmcblk0p19; SIZE=3808428032; BS=4194304; LAST=$(( SIZE / BS - 1 ))
[ "$(stat -c %s "$IMG")" -eq "$SIZE" ] || { echo "image is not $SIZE bytes" >&2; exit 2; }
WANT="$(sha256sum "$IMG" | cut -d' ' -f1)"

ID="$(a exec-out "getprop ro.twrp.version; id -u; readlink -f /dev/block/platform/bootdevice/by-name/system; /sbin/toybox blockdev --getsize64 $P" | tr -d '\r')"
echo "$ID"
[ "$(echo "$ID" | sed -n 2p)" = 0 ] && [ "$(echo "$ID" | sed -n 3p)" = "$P" ] && [ "$(echo "$ID" | sed -n 4p)" = "$SIZE" ] \
  && [ -n "$(echo "$ID" | sed -n 1p)" ] || { echo "not TWRP with the expected system partition; nothing written" >&2; exit 3; }

echo "writing..."
a exec-in "/sbin/toybox dd of=$P bs=$BS conv=notrunc,fsync status=none" < "$IMG"

# The stream can lose its final chunk: rewrite the last block from a verified RAM-disk copy.
tail_tmp="$(mktemp)"; trap 'rm -f "$tail_tmp"' EXIT
dd if="$IMG" bs=$BS skip=$LAST count=1 status=none > "$tail_tmp"
a push "$tail_tmp" /tmp/tbf-tail.bin >/dev/null
[ "$(a exec-out '/sbin/toybox sha256sum /tmp/tbf-tail.bin' | tr -d '\r' | cut -c1-64)" = "$(sha256sum "$tail_tmp" | cut -c1-64)" ] \
  || { echo "tail push mismatch; do not reboot" >&2; exit 4; }
a exec-out "/sbin/toybox dd if=/tmp/tbf-tail.bin of=$P bs=$BS seek=$LAST count=1 conv=notrunc,fsync status=none; rm -f /tmp/tbf-tail.bin; sync"

GOT="$(a exec-out "/sbin/toybox dd if=$P bs=$BS status=none | /sbin/toybox sha256sum" | tr -d '\r' | cut -d' ' -f1)"
echo "expected $WANT"; echo "readback $GOT"
if [ "$GOT" = "$WANT" ]; then echo FLASH_VERIFIED; else echo "FLASH_MISMATCH: do not reboot" >&2; exit 5; fi

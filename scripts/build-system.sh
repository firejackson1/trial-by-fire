#!/usr/bin/env bash
# Build the Trial by Fire system image. Usage: build-system.sh /path/to/lineage-24.0 [jobs]
set -eo pipefail
TOP="${1:?usage: build-system.sh /path/to/lineage-24.0 [jobs]}"; JOBS="${2:-4}"
cd "$TOP"
[ -f device/amazon/trona-compat/camera/libcameracustom.trona-json-fix.bin ] || {
  echo "missing camera fix; run scripts/extract-camera-fix.sh first" >&2; exit 2; }
export OUT_DIR=out
# Soong analysis of the full tree needs a lot of memory; these keep it bounded.
export GOMEMLIMIT="${GOMEMLIMIT:-30GiB}" GOGC="${GOGC:-30}" GOMAXPROCS="${GOMAXPROCS:-4}"
source build/envsetup.sh
lunch lineage_gsi_trona-cp2a-userdebug
m -j"$JOBS" systemimage
echo "built: $TOP/out/target/product/generic_arm64/system.img"

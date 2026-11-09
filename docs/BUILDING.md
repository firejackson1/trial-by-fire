# Building Trial by Fire

Builds run on Linux (developed on Ubuntu under WSL2). Expect about 300 GB of disk for source plus build cache and at least 24 GB of RAM+swap; the first Soong analysis is memory hungry.

## 1. Sync LineageOS 24.0

```bash
mkdir lineage-24.0 && cd lineage-24.0
repo init -u https://github.com/LineageOS/android.git -b lineage-24.0 --git-lfs
mkdir -p .repo/local_manifests
cp /path/to/trial-by-fire/manifest/*.xml .repo/local_manifests/   # adds prebuilts/vndk/v30
repo sync -c -j8
```

`manifest/lineage-manifest-revision.txt` and `manifest/base-revisions.txt` record the exact revisions the patches were made against. If a patch no longer applies on a newer sync, check out those revisions (`git -C <project> checkout <rev>`).

## 2. Add the device tree and patches

```bash
/path/to/trial-by-fire/scripts/apply-patches.sh "$PWD"
```

This copies `device/amazon/trona-compat` into the tree and applies one patch per project from `patches/`. It refuses to run if a project already has local changes.

## 3. Camera fix (needs your tablet)

```bash
ADB_SERIAL=<your serial> /path/to/trial-by-fire/scripts/extract-camera-fix.sh "$PWD"
```

Pulls `/vendor/lib64/libcameracustom.so` from your tablet, checks it is the known stock version, changes one byte (a trailing comma in its built-in JSON, see `docs/HOW-IT-WORKS.md`) and writes the result into the device tree. The build fails without it.

## 4. Build

```bash
/path/to/trial-by-fire/scripts/build-system.sh "$PWD"
/path/to/trial-by-fire/scripts/make-partition-image.sh "$PWD" out-trial-by-fire.img
```

`make-partition-image.sh` pads the image to the tablet's 3,808,428,032-byte system partition with `avbtool resize_image`, runs `e2fsck` and `avbtool verify_image`, and prints the SHA-256 you should see after installing.

## Kernel

The ROM needs its matching kernel: [amazon-mt8183-devs/android_kernel_amazon_mt8183](https://github.com/amazon-mt8183-devs/android_kernel_amazon_mt8183) at `kernel/base-revision.txt`, plus the three patches in `kernel/patches/` (build fixes and sensor suspend handling; xt_qtaguid, cfg80211/nl80211 wireless API, SELinux and audit updates for Android 17).

```bash
git clone https://github.com/amazon-mt8183-devs/android_kernel_amazon_mt8183.git && cd android_kernel_amazon_mt8183
git checkout $(cat /path/to/trial-by-fire/kernel/base-revision.txt)
git am /path/to/trial-by-fire/kernel/patches/000[12]*.patch
git apply /path/to/trial-by-fire/kernel/patches/0003-*.patch
make ARCH=arm64 trona_defconfig && make ARCH=arm64 LOCALVERSION=-trona17wifiapi1 -j$(nproc)
```

`LOCALVERSION=-trona17wifiapi1` matters: the system image's legacy network check accepts only the kernel release `4.4.302-lineage-trona17wifiapi1` on a `trona` vendor (see `system/netd/server/trona/`). The system image alone does not replace the kernel.

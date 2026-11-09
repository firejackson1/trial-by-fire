# Trial by Fire

**Trial by Fire** is an experimental Android 17 ROM for the **Amazon Fire HD 10 (2021, 11th generation, codename `trona`, MediaTek MT8183)**, based on **[LineageOS](https://lineageos.org) 24.0**.

> Trial by Fire is an unofficial, independent project. It is **not** LineageOS, is not affiliated with or endorsed by the LineageOS project, and LineageOS provides no support for it. Please do not report Trial by Fire problems to LineageOS.

It runs Android 17 on top of the tablet's **stock Android 11 (Fire OS) vendor partition and 4.4 kernel**. Nothing on the vendor partition is modified; every compatibility fix lives in the system image.

## Status

Working on the development tablet:

- Boots to the desktop and stays up (no watchdog restarts)
- Wi-Fi, audio, Bluetooth, front and back cameras, microSD (portable), hardware video encoding (H.264)
- Google apps can be added separately (see [docs/GAPPS.md](docs/GAPPS.md))

Known limitations are in [docs/KNOWN-ISSUES.md](docs/KNOWN-ISSUES.md). Most important: **SELinux runs permissive**.

## What is in this repository

| Path | Contents |
|---|---|
| `device/amazon/trona-compat/` | The device tree: product config, init scripts, SEPolicy, legacy kernel compatibility, boot animation |
| `patches/<project>/` | One patch per changed LineageOS/AOSP project, made against the revisions in `manifest/base-revisions.txt` |
| `kernel/patches/` | Kernel patches on top of [amazon-mt8183-devs/android_kernel_amazon_mt8183](https://github.com/amazon-mt8183-devs/android_kernel_amazon_mt8183) (base in `kernel/base-revision.txt`) |
| `manifest/` | Local manifest and upstream revision pins |
| `scripts/` | Apply patches, build, make the partition image, install, extract the camera fix |
| `docs/` | Building, installing, GApps, how the fixes work, known issues |
| `ota/` | Update metadata for the built-in updater (empty until releases are published) |

No proprietary vendor files are distributed here. The one vendor-derived fix (a one-byte JSON correction in MediaTek's camera library) is regenerated from **your own tablet** by `scripts/extract-camera-fix.sh`.

## Quick start

1. Sync LineageOS 24.0 and add `manifest/` local manifests: [docs/BUILDING.md](docs/BUILDING.md)
2. `scripts/apply-patches.sh /path/to/lineage-24.0`
3. `scripts/extract-camera-fix.sh` (needs your tablet)
4. `scripts/build-system.sh` and `scripts/make-partition-image.sh`
5. Install from TWRP: [docs/INSTALLING.md](docs/INSTALLING.md)

## Credits

See [CREDITS.md](CREDITS.md). Trial by Fire stands on the work of the LineageOS project, the Android Open Source Project and the Fire HD 10 kernel developers.

## License

Original files in this repository are under the Apache License 2.0 ([LICENSE](LICENSE)). Patches are derived from, and remain under the licenses of, the projects they modify (mostly Apache 2.0; kernel patches GPL-2.0). See [NOTICE.md](NOTICE.md).

## Disclaimer

Provided as is, without warranty. Flashing custom software can lose data or damage your device and may void its warranty. You use it at your own risk.

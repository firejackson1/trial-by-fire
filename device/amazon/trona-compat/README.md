# Trona Android 17 compatibility target

Experimental LineageOS 24 GSI product for initial system-only bring-up on trona.
It inherits the official ARM64 GSI layout and adds the native VNDK 30 APEX
module using Android 17's existing `apex_vndk` build support and signing defaults.

The source snapshot is pinned in `../manifests/trona-vndk30.xml` to the AOSP
VNDK 30 repository's Android 16 release commit. The snapshot's ABI version is
30; the framework target remains Android 17. The installed runtime was also
captured separately for dependency and symbol comparisons.

Stage this directory under `device/amazon/trona-compat` in the Android source
tree and install the manifest fragment under `.repo/local_manifests` after the
current full source sync finishes. Then sync the new snapshot project and build
the `lineage_gsi_trona` userdebug product using the release configuration selected
by the LineageOS 24 build scripts.

This target has not passed a complete Soong build. It is not a flashable release.

The `legacy-fcm` directory restores the original FCM level 3 hardware matrix
and its native Android P kernel requirement modules for 4.4, 4.9 and 4.14.
The trona product explicitly installs this matrix alongside the current generic
matrices. Source URLs and hashes are recorded in `legacy-fcm/provenance.json`.
These inputs retain their original requirements; vendor level and kernel version
are not changed. The current Soong module source supports their properties,
but complete module compilation and VINTF validation remain pending.

Restoring VNDK 30 is only one prerequisite: SELinux compatibility mapping,
hardware compatibility matrices, networking support and runtime/hardware tests
are still required. Do not use this target's configuration as evidence that an
unmodified Android 17 GSI boots on trona.

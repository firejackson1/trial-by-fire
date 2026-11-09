# Adding Google apps (optional)

Trial by Fire ships without Google apps. They are installed separately from TWRP using **[MindTheGapps](https://gitlab.com/MindTheGapps/vendor_gapps)** for Android 17 (branch `cinnamonbun`). Google apps are proprietary and are not distributed by this project.

## 1. Build the MindTheGapps zip

```bash
git clone -b cinnamonbun https://gitlab.com/MindTheGapps/vendor_gapps.git
cd vendor_gapps
PATH=/path/to/jdk/bin:$PATH make gapps_arm64      # signing step needs java
```

## 2. Make room on the system partition (TWRP)

The system image is built only as large as its contents, so grow its filesystem to fill the partition first:

```bash
adb shell 'e2fsck -fy /dev/block/mmcblk0p19; resize2fs /dev/block/mmcblk0p19'
```

## 3. Install the zip (TWRP)

```bash
adb push MindTheGapps-17.0.0-arm64-*.zip /tmp/gapps.zip
adb shell twrp install /tmp/gapps.zip
```

## 4. Play services fix for the 4.4 kernel

Android 17's Play services ships inside an APEX whose payload is **EROFS**, which the tablet's 4.4 kernel cannot mount (`Mounting failed ... No such device`). Install its contents as a regular privileged app instead:

1. On a PC, extract the APEX payload from the MindTheGapps tree (`arm64/proprietary/product/apex/com.google.android.gmssystem.prodvic.apex`): `unzip ... apex_payload.img`, then `fsck.erofs --extract=payload apex_payload.img` (from AOSP's host tools or erofs-utils).
2. In TWRP, mount system read-write and copy, keeping the files unmodified:
   - `payload/priv-app/PrebuiltGmsCoreVic*/PrebuiltGmsCoreVic.apk` → `/system/product/priv-app/PrebuiltGmsCoreVic/`
   - `payload/etc/permissions/*.xml` → `/system/product/etc/permissions/`
   - `payload/etc/sysconfig/*.xml` → `/system/product/etc/sysconfig/`
3. Delete `/system/product/apex/com.google.android.gmssystem.prodvic.apex`, set files to `root:root`, mode 644 (directories 755), label `u:object_r:system_file:s0`, unmount, reboot.

Play Store will report the device as uncertified; register it yourself at <https://www.google.com/android/uncertified>. Trial by Fire does not spoof device certification.

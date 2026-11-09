# Installing Trial by Fire

**Requirements:** a Fire HD 10 (2021, `trona`) with an unlocked bootloader, TWRP recovery, the patched kernel, and the stock Fire OS 7/Android 11 vendor partition. Back up everything first; this writes the whole system partition.

## Install the system image

1. Boot the tablet into TWRP and connect it over USB (`adb devices` shows it as `recovery`).
2. Run:

   ```bash
   ADB_SERIAL=<your serial> scripts/install-system.sh out-trial-by-fire.img
   ```

   The script checks it is talking to TWRP and to a system partition of the right size, streams the image, **rewrites the final 4 MiB from a verified copy in TWRP's RAM disk with `dd conv=notrunc`**, then reads back the whole partition and compares SHA-256. It does not reboot.

3. Only after `FLASH_VERIFIED`, reboot: `adb reboot`.

### Why the tail rewrite

Streaming a large image through `adb exec-in` can lose its final chunk, which leaves the AVB footer at the end of the partition wrong. In addition, TWRP's toybox `dd` fails with `ftruncate: Invalid argument` on a block device unless `conv=notrunc` is given, so a naive repair silently writes nothing. Always trust the full read-back hash, not the write's exit code.

## After installing

- A fresh system image removes anything flashed on top of the previous one (for example Google apps); reinstall them with `docs/GAPPS.md`.
- The first boot after an image change takes longer while apps are re-optimized.

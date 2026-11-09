# Known issues

- **SELinux is permissive.** One boot logs over 100 distinct denials, and some retained vendor services start without a domain transition (they run as `init`). Enforcing mode needs the vendor policy mapped onto Android 17's first.
- **Battery Saver shows "Unavailable"** in Quick Settings. Not yet investigated.
- **H.265 in WebView apps** (for example Frigate viewers) can fail with `DECODER_ERROR_NOT_SUPPORTED`; H.264 streams play. Hardware H.264/H.265 decoders are listed by the platform.
- **Hardware video encoder** works up to 720×1280 for screen recording; 1200×1920 is rejected by the vendor encoder.
- The vendor video encoder closes a file descriptor it does not own; Trial by Fire downgrades fdsan to warn-once only for executables built for API ≤ 30 (as stock Android 11 did), which leaves one warning report per occurrence.
- **No over-the-air updates** yet: the updater points at `ota/` in this repository, which is empty.
- Debugging aids are still compiled in: an early-boot event recorder and a kernel-log copier writing to `/cache`.

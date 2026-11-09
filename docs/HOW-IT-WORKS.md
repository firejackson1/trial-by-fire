# How Trial by Fire runs Android 17 on an Android 11 vendor

Each entry is a problem found on the real tablet and the narrow fix for it.

| Problem | Cause | Fix (where) |
|---|---|---|
| Keymaster exits, boot stalls at `vdc keymaster earlyBootEnded` | Android 17 ueventd only reads `/vendor/etc/ueventd.rc`; this vendor keeps its rules in `/vendor/ueventd.rc`, so `/dev/trustzone` stayed root-only | `system/core/rootdir/ueventd.rc` imports `/vendor/ueventd.rc` |
| Reboot loop `netd1shot-fail` | Legacy network prerequisite check rejected an empty `iface_stat_fmt` before any interface exists | `system/netd` (trona legacy backend) |
| netd aborts in `DnsProxyListener` | `ADnsHelper_init()` needs BPF, absent on 4.4 | `packages/modules/DnsResolver`: no abort on the legacy backend |
| system_server NPE in `HintManagerService` | No AIDL power HAL on this vendor | `frameworks/base`: all-unsupported defaults when the HAL is absent |
| Feature-flag crash, aconfig storage empty | `/metadata` is a read-only empty directory (no metadata partition) | `system/core/rootdir/init.rc`: tmpfs on `/metadata` at early-init |
| `IOemNetd` descriptor mismatch | Connectivity jarjar rewrote the AIDL descriptor | `@Descriptor` with `no.jarjar.` prefix |
| system_server abort reading GPU memory | BPF map absent on 4.4 | `system/memory/libmeminfo`: `access()` guard |
| Freeze, then watchdog restart, every few minutes | lmkd waited forever for `bpf.progs_loaded` after boot completed, stopped reading its socket, and the activity manager blocked writing to it | `system/memory/lmkd`: skip the memevent listener when BPF is unavailable (vmstats fallback) |
| Camera service crash loop, 0 cameras | Vendor `libcameracustom.so` has a trailing comma in its built-in stereo JSON; the parse error is recovered through the vendor's libgcc unwinder, which Android 17's LLVM-unwinder libc cannot read (stock Android 11 libc was libgcc-style) | One-byte fix of the vendor library (`,` → space), shipped in system and bind-mounted over the vendor copy at `post-fs` |
| Bluetooth crash at start (x18 = 0) | The Mali GPU driver clobbers x18 (shadow call stack) while the zygote preloads graphics, so every app inherits x18 = 0 | `ro.zygote.disable_gl_preload=true` |
| Bluetooth abort during controller init | Controller advertises `READ_DEFAULT_ERRONEOUS_DATA_REPORTING` but rejects it with a Command Status | `packages/modules/Bluetooth`: route that status to its failure-tolerant handler |
| Video encoder aborts | Vendor encoder double-closes a fence fd; Android 17 fdsan is fatal by default | `bionic`: warn-once default for executables whose ELF note targets API ≤ 30 |
| Notification shade was an opaque dark slab | Background blur was disabled | Enable blur (`blurs_are_expensive` mode for Mali-G72) |
| Shade panel stretched to the screen bottom in portrait | AOSP portrait behavior | SystemUI: end the panel below the last notification, as split shade does |

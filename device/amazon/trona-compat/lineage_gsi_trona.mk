# SPDX-License-Identifier: Apache-2.0
# Keep the ARM64 GSI contents, excluding its compliance-only alternate
# userdebug policy. inherit-product merges package lists after this file is
# parsed, so clearing the policy flag in a child product cannot remove the
# inherited policy package.
$(call inherit-product, device/amazon/trona-compat/gsi_arm64_trona.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

include vendor/lineage/build/target/product/lineage_generic_target.mk

PRODUCT_USE_DYNAMIC_PARTITION_SIZE := true
TARGET_NO_KERNEL_OVERRIDE := true
PRODUCT_DEVICE := generic_arm64
PRODUCT_ENFORCE_ARTIFACT_PATH_REQUIREMENTS :=
# Preserve Lineage's established Make image assembly path.
USE_SOONG_DEFINED_SYSTEM_IMAGE := false

# Keep the generic ARM64 system-as-root layout for initial system-only bring-up.
# Boot and vendor images remain separate from this build target.
PRODUCT_NAME := lineage_gsi_trona

# Trona's retained vendor provides mapper 2.0; use Lineage's existing legacy path.
$(call soong_config_set_bool,libui,legacy_gralloc,true)

PRODUCT_EXTRA_VNDK_VERSIONS += 30
PRODUCT_PACKAGES += \
    com.android.vndk.v30 \
    framework_compatibility_matrix.3.xml

SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += \
    device/amazon/trona-compat/sepolicy/system_ext/private

# Preserve the retained vendor labels for its two existing camera properties.
BOARD_SEPOLICY_M4DEFS += trona_legacy_vendor_camera_contexts=true

PRODUCT_INSTALL_DEBUG_POLICY_TO_SYSTEM_EXT :=

# Retained 4.4 kernel path for the Fire HD 10 (2021, trona).
# Native serial/kernel prerequisites and genuine generation readiness remain mandatory.
PRODUCT_SYSTEM_PROPERTIES += ro.trona.network_backend=legacy

# Retained4.4 lacks MADV_WIPEONFORK; select fresh blocking kernel CSPRNG.
$(call soong_config_set_bool,trona_compat,kernel_entropy_only,true)

# Development USB defaults; host-key authorization stays required.
PRODUCT_SYSTEM_PROPERTIES += persist.sys.usb.config=mtp,adb ro.adb.secure=1

# Fatal init keeps its failure path and requests the existing recovery image.
# Automatic TWRP return is unverified until an attended fatal-path test.
$(call soong_config_set_bool,trona_compat,init_fatal_recovery,true)

# QTAGUID: root/system-UID controls and tracking; preserve per-app stats filtering.
PRODUCT_COPY_FILES += \
    device/amazon/trona-compat/init.trona-qtaguid.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.trona-qtaguid.rc

# Private reviewed diagnostic candidate; normal authentication/policy unchanged.
$(call soong_config_set_bool,trona_compat,early_boot_recorder,true)

# Zygote must not run the retained Mali driver on its main thread: it clobbers x18, which
# breaks shadow-call-stack code (libbluetooth_jni) in every forked app.
PRODUCT_SYSTEM_PROPERTIES += ro.zygote.disable_gl_preload=true

# Camera: one-byte JSON fix for the retained vendor libcameracustom.so, bind-mounted at post-fs.
PRODUCT_COPY_FILES += \
    device/amazon/trona-compat/camera/libcameracustom.trona-json-fix.bin:$(TARGET_COPY_OUT_SYSTEM)/etc/trona/libcameracustom.trona-json-fix.bin \
    device/amazon/trona-compat/init.trona-camera.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.trona-camera.rc

# Owner boot animation (Android on fire, 1920x1200 @ 24 fps), via Lineage's prebuilt hook.
TARGET_BOOTANIMATION := device/amazon/trona-compat/bootanimation/bootanimation.zip

# Android 17's shade is a full-height panel meant to sit over a blurred background; without blur
# it falls back to a solid dark slab. Mali-G72: enable blur in its cheaper "expensive" mode.
# Tested live 2026-11-09 (mBlurEnabled=true, backgroundBlurRadius=51).
PRODUCT_SYSTEM_PROPERTIES += \
    ro.surface_flinger.supports_background_blur=1 \
    ro.sf.blurs_are_expensive=1

# Trial by Fire: a ROM based on LineageOS. Not an official LineageOS build and not endorsed by
# the LineageOS project. The updater must not query download.lineageos.org for this ROM, so it
# points at this ROM's own update metadata (empty until releases are published).
PRODUCT_SYSTEM_PROPERTIES += \
    ro.trialbyfire.name=Trial-by-Fire \
    ro.trialbyfire.version=1.0-dev \
    lineage.updater.uri=https://raw.githubusercontent.com/firejackson1/trial-by-fire/main/ota/{device}.json

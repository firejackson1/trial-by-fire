# SPDX-License-Identifier: Apache-2.0
# ARM64 GSI composition for trona. The system_ext package list omits the
# alternate compliance-GSI debug policy. The Lineage product selects Make
# image assembly after inheriting these generic defaults.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_system.mk)

PRODUCT_ENFORCE_ARTIFACT_PATH_REQUIREMENTS := true
MODULE_BUILD_FROM_SOURCE := true

$(call inherit-product, device/amazon/trona-compat/gsi_system_ext_trona.mk)
$(call inherit-product, packages/modules/Virtualization/apex/product_packages.mk)
$(call inherit-product, device/generic/common/gsi_product.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/gsi_release.mk)

ifneq ($(filter userdebug eng,$(TARGET_BUILD_VARIANT)),)
    $(call soong_config_set_bool, gsi, import_usb_debugging_test_app, true)
endif

PRODUCT_NAME := gsi_arm64
PRODUCT_DEVICE := generic_arm64
PRODUCT_BRAND := Android
PRODUCT_MODEL := GSI on ARM64

PRODUCT_SOONG_DEFINED_SYSTEM_IMAGE := android_gsi
USE_SOONG_DEFINED_SYSTEM_IMAGE := true

PRODUCT_PACKAGES_DEBUG += UsbDisableDebugger

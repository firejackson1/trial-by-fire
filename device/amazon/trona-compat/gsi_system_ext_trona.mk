# SPDX-License-Identifier: Apache-2.0
# Copy of the generic GSI system_ext package composition without the
# compliance-only alternate userdebug policy.
$(call inherit-product, $(SRC_TARGET_DIR)/product/media_system_ext.mk)

PRODUCT_PACKAGES += \
    Launcher3QuickStep \
    Provision \
    Settings \
    StorageManager \
    SystemUI

PRODUCT_PACKAGES += preinstalled-packages-handheld-system-ext.xml

PRODUCT_PACKAGES += \
    CarrierConfig \
    preinstalled-packages-gsi-system-ext.xml

PRODUCT_PACKAGES += \
    $(PRODUCT_PACKAGES_SHIPPING_API_LEVEL_29) \
    $(PRODUCT_PACKAGES_SHIPPING_API_LEVEL_33) \
    $(PRODUCT_PACKAGES_SHIPPING_API_LEVEL_34)

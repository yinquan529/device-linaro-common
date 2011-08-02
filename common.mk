# stuff common to all Linaro LEB
include $(LOCAL_PATH)/ZeroXBenchmark.mk

PRODUCT_PACKAGES := \
    AccountAndSyncSettings \
    AlarmClock \
    AlarmProvider \
    Bluetooth \
    Calculator \
    Calendar \
    Camera \
    CertInstaller \
    DrmProvider \
    Email \
    Gallery3D \
    LatinIME \
    Launcher2 \
    Mms \
    Music \
    Provision \
    Settings \
    Sync \
    Updater \
    CalendarProvider \
    SyncProvider \
    faketsd \
    ZeroXBenchmark \
    libmicro \
    powertop \
    $(ZEROXBENCHMARK_NATIVE_APPS)

$(call inherit-product, $(SRC_TARGET_DIR)/product/core.mk)
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
    SystemUI \
    Sync \
    Updater \
    CalendarProvider \
    SyncProvider \
    faketsd \
    ZeroXBenchmark \
    hwcomposer.default \
    libmicro \
    powertop \
    mmtest \
    $(ZEROXBENCHMARK_NATIVE_APPS) \
    GLMark2 \
    libglmark2-android \
    gatord \
    LinaroWallpaper \
    LiveWallpapers \
    LiveWallpapersPicker \
    MagicSmokeWallpapers \
    VisualizationWallpapers \
    librs_jni \
    mediaframeworktest \
    libtinyalsa \
    tinyplay \
    tinycap \
    tinymix \
    libaudioutils \
    ConnectivityManagerTest \
    iozone \
    memtester \
    stress \
    stressapptest \
    DisableSuspend \
    libncurses \
    htop \
    cyclictest \
    sysbench

#packages we are using for benchmarking
PRODUCT_PACKAGES += \
    v8shell \
    skia_bench

V8BENCHMARKS := $(foreach js,$(wildcard $(TOP)/external/v8/benchmarks/*.js),\
	$(js):data/benchmark/v8/$(notdir $(js)))

PRODUCT_COPY_FILES := \
	device/linaro/common/wallpaper_info.xml:data/system/wallpaper_info.xml \
	device/linaro/common/disablesuspend.sh:system/bin/disablesuspend.sh \
	$(V8BENCHMARKS)

# Since Make doesn't do && expressions without a system call hack
# which isn't portible, use a var to record if the var exists and the
# directory exists
NO_LINARO_BUILD_SPEC := true
ifneq ($(strip $(LINARO_BUILD_SPEC)),)
ifneq ($(wildcard $(TOP)/device/linaro/common/howto/$(LINARO_BUILD_SPEC)),)
PRODUCT_COPY_FILES += \
	device/linaro/common/howto/$(LINARO_BUILD_SPEC)/HOWTO_install.txt:howto/HOWTO_install.txt$(warning here)
NO_LINARO_BUILD_SPEC := false
endif
endif
ifeq ($(NO_LINARO_BUILD_SPEC),true)
PRODUCT_COPY_FILES += \
	device/linaro/common/howto/default/HOWTO_install.txt:howto/HOWTO_install.txt$(warning here2)
endif

$(call inherit-product, $(SRC_TARGET_DIR)/product/core.mk)

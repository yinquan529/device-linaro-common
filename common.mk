# stuff common to all Linaro LEB
include $(LOCAL_PATH)/ZeroXBenchmark.mk

ifneq ($(wildcard $(TOP)/packages/apps/AndroidTerm/Android.mk),)
# Include AndroidTerm only if it's part of the manifest
ANDROIDTERM := AndroidTerm libjackpal-androidterm4
endif
ifneq ($(wildcard $(TOP)/packages/inputmethods/hackerskeyboard/Android.mk),)
HACKERSKEYBOARD := PCKeyboard
endif

PRODUCT_PACKAGES := \
    AccountAndSyncSettings \
    AlarmClock \
    AlarmProvider \
    $(ANDROIDTERM) \
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
    $(HACKERSKEYBOARD) \
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
    powerdebug \
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
# d8 replaces v8shell -- we're leaving both packages in here for now so
# older builds still get v8shell.
PRODUCT_PACKAGES += \
    v8shell \
    d8 \
    skia_bench

V8BENCHMARKS := $(foreach js,$(wildcard $(TOP)/external/v8/benchmarks/*.js),\
	$(js):data/benchmark/v8/$(notdir $(js)))

PRODUCT_COPY_FILES := \
	device/linaro/common/wallpaper_info.xml:data/system/wallpaper_info.xml \
	device/linaro/common/disablesuspend.sh:system/bin/disablesuspend.sh \
	$(V8BENCHMARKS)

define copy-howto
ifneq ($(wildcard $(TOP)/device/linaro/common/howto/$(LINARO_BUILD_SPEC)/$1),)
PRODUCT_COPY_FILES += \
	device/linaro/common/howto/$(LINARO_BUILD_SPEC)/$1:howto/$1
else
ifneq ($(wildcard $(TOP)/device/linaro/common/howto/default/$1),)
PRODUCT_COPY_FILES += \
	device/linaro/common/howto/default/$1:howto/$1
endif
endif
endef

HOWTOS := \
	OPEN-EULA.txt \
	HOWTO_install.txt \
	HOWTO_getsourceandbuild.txt \
	HOWTO_flashfirmware.txt \
	HOWTO_releasenotes.txt \
	HOWTO_rtsm.txt

PRODUCT_COPY_FILES += \
        device/linaro/common/media_codecs.xml:system/etc/media_codecs.xml

$(foreach howto,$(HOWTOS),$(eval $(call copy-howto,$(howto))))

$(call inherit-product, $(SRC_TARGET_DIR)/product/core.mk)

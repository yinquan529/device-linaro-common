ifneq ($(strip $(SHOW_COMMANDS)),)
KERNEL_VERBOSE="V=1"
endif

KERNEL_TOOLS_PREFIX ?= $(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX))

# Get an absolute pathname for $(TARGET_TOOLS_PREFIX) - perf needs to be
# built with TARGET_TOOLS (not KERNEL_TOOLS because we may be building a
# 64/32 environment), but is not built from the regular top directory,
# so passing a relative TARGET_TOOLS_PREFIX won't work.
ABS_TARGET_TOOLS_PREFIX = $(shell cd `dirname $(TARGET_TOOLS_PREFIX)` && pwd)/$(shell basename $(TARGET_TOOLS_PREFIX))

REALTOP=$(realpath $(TOP))

KERNEL_OUT=$(realpath $(PRODUCT_OUT))/obj/kernel
# Certain devices load mmc driver as module and hence kernel module need to be in initrd
TARGET_MODULES_OUT ?= $(TARGET_OUT)

# Decide on path for kernel
# 1. use TARGET_KERNEL_SOURCE if defined
# 2. try to use kernel/<vendor>/<device> if it exists
# 3. try to use kernel
TARGET_AUTO_KDIR := $(shell echo $(TARGET_DEVICE_DIR) | sed -e 's/^device/kernel/g')
TARGET_KERNEL_SOURCE ?= $(shell if [ -e $(TARGET_AUTO_KDIR) ]; then echo $(TARGET_AUTO_KDIR); else echo kernel; fi;)
KERNEL_SRC := $(TARGET_KERNEL_SOURCE)


ifneq ($(strip $(ANDROID_64)),true)
# Building perf for an architecture different from the kernel's is currently
# not supported.
ifneq ($(strip $(BUILD_TINY_ANDROID)),true)
# We can build perf if it's included in the kernel and has the
# Android compatibility patch in
ifneq ($(wildcard $(KERNEL_SRC)/tools/perf/compat-android.h),)
	INCLUDE_PERF ?= 1
ifeq ($(INCLUDE_PERF),1)
	PERF_DEP := $(PRODUCT_OUT)/obj/STATIC_LIBRARIES/libelf_intermediates/libelf.a $(PRODUCT_OUT)/obj/lib/crtend_android.o $(PRODUCT_OUT)/obj/lib/crtbegin_dynamic.o $(TARGET_OUT_SHARED_LIBRARIES)/libc.so
endif
endif
endif
endif

ifeq ($(strip $(ANDROID_64)),true)
KERNEL_TARGET := Image
else
ifeq ($(strip $(TARGET_BOOTLOADER_TYPE)),uboot)
BOOTLOADER_DEP := $(PRODUCT_OUT)/u-boot.bin
KERNEL_TARGET := $(or $(KERNEL_TARGET),uImage)
else
BOOTLOADER_DEP :=
KERNEL_TARGET := $(or $(KERNEL_TARGET),zImage)
endif
endif

ifeq ($(strip $(ANDROID_64)),true)
ARCH := arm64
LOCAL_CFLAGS=
KERNEL_COMPILER_PATHS := $(REALTOP)/gcc-linaro-aarch64-linux-gnu/bin:../$(BUILD_OUT_EXECUTABLES)
else
ARCH := arm
LOCAL_CFLAGS=$(call cc-option,"-mno-unaligned-access", )
KERNEL_COMPILER_PATHS := ../$(BUILD_OUT_EXECUTABLES)
endif

android_kernel: $(BOOTLOADER_DEP) $(PERF_DEP)
	echo building kernel $(KERNEL_TARGET) with config $(KERNEL_CONFIG) for bootloader $(TARGET_BOOTLOADER_TYPE)
	mkdir -p $(KERNEL_OUT)
	cd $(KERNEL_SRC) &&\
	export PATH=$(KERNEL_COMPILER_PATHS):$(PATH) && \
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	if [ $(words $(KERNEL_CONFIG)) -gt 1 ]; \
	then scripts/kconfig/merge_config.sh -m $(KERNEL_CONFIG) && mv -f .config $(KERNEL_OUT)/.merged.config && $(MAKE) -j1 $(KERNEL_VERBOSE) O=$(KERNEL_OUT) ARCH=$(ARCH) KCONFIG_ALLCONFIG=$(KERNEL_OUT)/.merged.config alldefconfig; \
	else $(MAKE) -j1 KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" $(KERNEL_VERBOSE) O=$(KERNEL_OUT) ARCH=$(ARCH) CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) LD=$$LD defconfig $(KERNEL_CONFIG); \
	fi && \
	$(MAKE) $(KERNEL_VERBOSE) O=$(KERNEL_OUT) ARCH=$(ARCH) CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" LD=$$LD $(KERNEL_TARGET)
ifeq ($(INCLUDE_PERF),1)
	export PATH=$(KERNEL_COMPILER_PATHS):$(PATH) &&\
	cd $(KERNEL_SRC)/tools/perf &&\
	mkdir -p $(KERNEL_OUT)/tools/perf &&\
	mkdir -p $(REALTOP)/$(PRODUCT_OUT)/system/bin/ &&\
	if [ -e $(ABS_TARGET_TOOLS_PREFIX)ld.bfd ]; then LD=$(ABS_TARGET_TOOLS_PREFIX)ld.bfd; else LD=$(ABS_TARGET_TOOLS_PREFIX)ld; fi && \
	$(MAKE) ANDROID_CFLAGS="$(TARGET_EXTRA_CFLAGS) $(LOCAL_CFLAGS) -isystem $(REALTOP)/bionic/libc/include -isystem $(REALTOP)/bionic/libc/kernel/common -isystem $(REALTOP)/bionic/libc/kernel/arch-arm -isystem $(REALTOP)/bionic/libc/arch-arm/include -I$(REALTOP)/external/elfutils/libelf -isystem $(REALTOP)/bionic/libm/include -isystem $(shell dirname $(ABS_TARGET_TOOLS_PREFIX))/../include -I$(KERNEL_OUT)/tools/perf" BASIC_LDFLAGS="-nostdlib -Wl,-dynamic-linker,/system/bin/linker,-z,muldefs$(shell if test $(PLATFORM_SDK_VERSION) -lt 16; then echo -ne ',-T$(REALTOP)/$(BUILD_SYSTEM)/armelf.x'; fi),-z,nocopyreloc,--no-undefined -L$(REALTOP)/$(TARGET_OUT_STATIC_LIBRARIES) -L$(REALTOP)/$(PRODUCT_OUT)/system/lib -L$(REALTOP)/external/elfutils -L$(realpath $(PRODUCT_OUT))/obj/STATIC_LIBRARIES/libelf_intermediates -lpthread -lelf -lm -lc $(REALTOP)/$(TARGET_CRTBEGIN_DYNAMIC_O) $(REALTOP)/$(TARGET_CRTEND_O)" $(KERNEL_VERBOSE) O=$(KERNEL_OUT)/tools/perf/ OUTPUT=$(KERNEL_OUT)/tools/perf/ ARCH=$(ARCH) CROSS_COMPILE=$(ABS_TARGET_TOOLS_PREFIX) LD=$$LD prefix=/system NO_DWARF=1 NO_NEWT=1 NO_LIBPERL=1 NO_LIBPYTHON=1 NO_GTK2=1 NO_STRLCPY=1 WERROR=0 && \
	cp -f $(KERNEL_OUT)/tools/perf/perf $(REALTOP)/$(PRODUCT_OUT)/system/bin/
endif

ifneq ($(BUILD_KERNEL_MODULES),false)
android_kernel_modules: $(INSTALLED_KERNEL_TARGET) $(ACP)
	export PATH=$(KERNEL_COMPILER_PATHS):$(PATH) &&\
	cd $(KERNEL_SRC) &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	$(MAKE) $(KERNEL_VERBOSE) O=$(KERNEL_OUT) ARCH=$(ARCH) CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) LD=$$LD EXTRA_CFLAGS="$(EXTRA_CFLAGS) -fno-pic" KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" modules
	mkdir -p $(KERNEL_OUT)/modules_for_android
	cd $(KERNEL_SRC) &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	$(MAKE) O=$(KERNEL_OUT) ARCH=$(ARCH) CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" LD=$$LD modules_install INSTALL_MOD_PATH=$(KERNEL_OUT)/modules_for_android
	mkdir -p $(TARGET_MODULES_OUT)/modules
	find $(KERNEL_OUT)/modules_for_android -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_MODULES_OUT)/modules/ \;
else
android_kernel_modules:
endif

#NOTE: the gator driver's Makefile wasn't done properly and doesn't put build
#      artifacts in the O=$(KERNEL_OUT)
ifeq ($(TARGET_USE_GATOR),true)

KERNEL_PATH:=$(shell pwd)/$(KERNEL_SRC)

ifneq ($(TARGET_GATOR_WITH_MALI_SUPPORT),)
ifndef TARGET_MALI_DRIVER_DIR
$(error TARGET_MALI_DRIVER_DIR must be defined if TARGET_GATOR_WITH_MALI_SUPPORT is.)
endif
GATOR_EXTRA_CFLAGS += -DMALI_SUPPORT=$(TARGET_GATOR_WITH_MALI_SUPPORT) -I$(KERNEL_PATH)/$(TARGET_MALI_DRIVER_DIR)
GATOR_EXTRA_MAKE_ARGS += GATOR_WITH_MALI_SUPPORT=$(TARGET_GATOR_WITH_MALI_SUPPORT)
endif

ifneq ($(realpath $(TOP)/external/gator/driver),)
gator_driver: android_kernel_modules $(INSTALLED_KERNEL_TARGET) $(ACP)
	export PATH=$(KERNEL_COMPILER_PATHS):$(PATH) &&\
	cd $(TOP)/external/gator/driver &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	$(MAKE) O=$(KERNEL_OUT) ARCH=$(ARCH) CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) LD=$$LD EXTRA_CFLAGS="$(EXTRA_CFLAGS) -fno-pic $(GATOR_EXTRA_CFLAGS)" KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" $(GATOR_EXTRA_MAKE_ARGS) -C $(KERNEL_PATH) M=`pwd` modules
	mkdir -p $(TARGET_MODULES_OUT)/modules
	find $(TOP)/external/gator/driver/. -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_MODULES_OUT)/modules/ \;
else
gator_driver:
endif

else
gator_driver:
endif

out_of_tree_modules: $(INSTALLED_KERNEL_TARGET) gator_driver

$(INSTALLED_KERNEL_TARGET): android_kernel
	ln -sf $(KERNEL_OUT)/arch/$(ARCH)/boot/$(KERNEL_TARGET) $(INSTALLED_KERNEL_TARGET)

$(INSTALLED_SYSTEMTARBALL_TARGET): android_kernel_modules out_of_tree_modules

$(INSTALLED_RAMDISK_TARGET): android_kernel_modules out_of_tree_modules

droidcore: android_kernel_modules out_of_tree_modules

#
# Generate a rule to build a device-tree.
#
# Usage: $(eval $(call MAKE_DEVICE_TREE, target-blob, source-name))
#
#   target-blob     Path and name for generated device tree blob
#   source-name     Name of source in arch/arm/boot/dts/ without trailing '.dts'
#
#
define MAKE_DEVICE_TREE

$(1): $$(KERNEL_OUT)/arch/$(ARCH)/boot/$(2).dtb $$(ACP)
	@mkdir -p $$(dir $$@)
	$$(ACP) -fpt $$< $$@

DTB_TARGETS += $(2).dtb
DTB_INSTALL_TARGETS += $(1)

endef

#
# DEVICE_TREES contains a list of device-trees to build, each
# entry in the list is in the form <source-name>:<blob-name>
#
DTB_TARGETS :=
DTB_INSTALL_TARGETS :=
$(foreach _ub,$(DEVICE_TREES),                             \
    $(eval _source := $(call word-colon,1,$(_ub)))         \
    $(eval _blob := $(call word-colon,2,$(_ub)))           \
    $(eval _target := $(PRODUCT_OUT)/boot/$(_blob))        \
    $(eval $(call MAKE_DEVICE_TREE,$(_target),$(_source))) \
    )


ifneq ($(strip $(DTB_TARGETS)),)

.PHONY : all_dtbs
all_dtbs : $(INSTALLED_KERNEL_TARGET)
	export PATH=$(KERNEL_COMPILER_PATHS):$(PATH) &&\
	cd $(KERNEL_SRC) && \
	$(MAKE) O=$(KERNEL_OUT) ARCH=$(ARCH) CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) $(DTB_TARGETS)
	-mv -f $(KERNEL_OUT)/arch/$(ARCH)/boot/dts/*.dtb $(KERNEL_OUT)/arch/$(ARCH)/boot/

$(patsubst %,$(KERNEL_OUT)/arch/$(ARCH)/boot/%,$(DTB_TARGETS)) : all_dtbs

endif

$(INSTALLED_BOOTTARBALL_TARGET): $(DTB_INSTALL_TARGETS)

$(INSTALLED_DTB_TARGET): $(DTB_INSTALL_TARGETS)

ifeq ($(TARGET_PRODUCT), vexpress_rtsm)
bootwrapper: $(DTB_INSTALL_TARGETS)
endif

kernel_files : $(INSTALLED_KERNEL_TARGET) $(DTB_INSTALL_TARGETS) android_kernel_modules
	cp $(INSTALLED_KERNEL_TARGET) $(PRODUCT_OUT)/boot/

PREBUILT_IMAGES_DIR := $(PRODUCT_OUT)/prebuilt-images/
$(PREBUILT_IMAGES_DIR) :
	mkdir -p $(PREBUILT_IMAGES_DIR)

PRODUCT_OUT_BOOT_DIR := $(PRODUCT_OUT)/boot
$(PRODUCT_OUT_BOOT_DIR) :
	mkdir -p $(PRODUCT_OUT_BOOT_DIR)

ifneq ($(strip $(ANDROID_PREBUILT_URL)),)
ifeq ($(KERNEL_TARGET),zImage)
$(PRODUCT_OUT)/boot/uImage : $(INSTALLED_KERNEL_TARGET) | $(PRODUCT_OUT_BOOT_DIR)
	$(eval UIMAGE_LOADADDR ?= 0x60008000)
	mkimage -A arm -O linux -T kernel -n "Android Kernel" -C none -a $(UIMAGE_LOADADDR) -e $(UIMAGE_LOADADDR) -d $< $@
COMBINED_BOOTTARBALL_TARGET : $(PRODUCT_OUT)/boot/uImage
endif

REAL_OUT=$(realpath $(PRODUCT_OUT))
UPDATE_TARBALL := device/linaro/common/tasks/updatetarball.sh
define update-boottarball
    $(hide) echo "Target boot fs tarball: $(INSTALLED_BOOTTARBALL_TARGET)"
    $(hide) $(UPDATE_TARBALL) $(FS_GET_STATS) $(PRODUCT_OUT) boot $(PRIVATE_BOOT_TAR) \
                 $(INSTALLED_BOOTTARBALL_TARGET)
endef
define update-systemtarball
    $(hide) echo "Target system fs tarball: $(INSTALLED_SYSTEMTARBALL_TARGET)"
    $(UPDATE_TARBALL) $(FS_GET_STATS) $(PRODUCT_OUT) system $(PRIVATE_SYSTEM_TAR) \
                 $(INSTALLED_SYSTEMTARBALL_TARGET)
endef

download_prebuilt_boot_image : $(PREBUILT_IMAGES_DIR)
	cd $(PREBUILT_IMAGES_DIR)  &&\
    wget -nv --no-check-certificate $(ANDROID_PREBUILT_URL)/boot.tar.bz2
download_prebuilt_system_image : $(PREBUILT_IMAGES_DIR)
	cd $(PREBUILT_IMAGES_DIR)  &&\
    wget -nv --no-check-certificate $(ANDROID_PREBUILT_URL)/system.tar.bz2
download_prebuilt_userdata_image : $(PREBUILT_IMAGES_DIR)
	cd $(PREBUILT_IMAGES_DIR)  &&\
    wget -nv --no-check-certificate $(ANDROID_PREBUILT_URL)/userdata.tar.bz2

PRIVATE_BOOT_TAR := $(boot_tar)
## do we need to generate the cmdline and uInitrd
## or use the old cmdline and uInitrd
## here use the  old cmdline and uInitrd first
#	tar xvf boot.tar boot/uInitrd &&\
#	cp -f boot/uInitrd $(REAL_OUT)/uInitrd
$(PRIVATE_BOOT_TAR): download_prebuilt_boot_image
	rm -fr $(PRODUCT_OUT)/boot.tar &&\
	cd $(PREBUILT_IMAGES_DIR)  &&\
	bunzip2 --keep boot.tar.bz2 &&\
	mv boot.tar $(REAL_OUT)/

COMBINED_BOOTTARBALL_TARGET : $(PRIVATE_BOOT_TAR) $(FS_GET_STATS) kernel_files
	$(update-boottarball)

PRIVATE_SYSTEM_TAR := $(system_tar)
$(PRIVATE_SYSTEM_TAR): download_prebuilt_system_image
	rm -fr $(PRODUCT_OUT)/system.tar &&\
	cd $(PREBUILT_IMAGES_DIR)  &&\
	bunzip2 --keep system.tar.bz2 &&\
	mv system.tar $(REAL_OUT)/
COMBINED_SYSTEMTARBALL_TARGET : $(PRIVATE_SYSTEM_TAR) $(FS_GET_STATS) kernel_files
	$(update-systemtarball)

COMBINED_USERDATATARBALL_TARGET : download_prebuilt_userdata_image
	cp -uvf $(PREBUILT_IMAGES_DIR)/userdata.tar.bz2 $(REAL_OUT)/

combine_kernel_prebuilt: COMBINED_BOOTTARBALL_TARGET COMBINED_SYSTEMTARBALL_TARGET COMBINED_USERDATATARBALL_TARGET
	if [ -d $(REALTOP)/build-info ]; then  find $(REALTOP)/build-info/ -iname BUILD-INFO.txt -exec cp {} $(REAL_OUT)/ \; ; fi

else
combine_kernel_prebuilt :
	$(error ANDROID_PREBUILT_URL need to be set for using this combine_kernel_prebuilt target.)

endif

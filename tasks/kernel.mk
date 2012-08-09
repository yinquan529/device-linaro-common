ifneq ($(strip $(SHOW_COMMANDS)),)
KERNEL_VERBOSE="V=1"
endif

KERNEL_TOOLS_PREFIX ?= $(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX))

LOCAL_CFLAGS=$(call cc-option,"-mno-unaligned-access", )
REALTOP=$(realpath $(TOP))

KERNEL_OUT=$(shell readlink -f $(PRODUCT_OUT)/obj/kernel)

# We can build perf if it's included in the kernel and has the
# Android compatibility patch in
ifneq ($(wildcard $(TOP)/kernel/tools/perf/compat-android.h),)
	INCLUDE_PERF := 1
	PERF_DEP := $(PRODUCT_OUT)/obj/STATIC_LIBRARIES/libelf_intermediates/libelf.a
endif

ifeq ($(strip $(TARGET_BOOTLOADER_TYPE)),fastboot)
BOOTLOADER_DEP :=
KERNEL_TARGET := zImage
else
BOOTLOADER_DEP := $(PRODUCT_OUT)/u-boot.bin
KERNEL_TARGET := uImage
endif

android_kernel: $(BOOTLOADER_DEP) $(PERF_DEP)
	echo building kernel $(KERNEL_TARGET) with config $(KERNEL_CONFIG) for bootloader $(TARGET_BOOTLOADER_TYPE)
	mkdir -p $(KERNEL_OUT)
	cd $(TOP)/kernel &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	export PATH=../$(BUILD_OUT_EXECUTABLES):$(PATH) && \
	if [ $(words $(KERNEL_CONFIG)) -gt 1 ]; \
	then scripts/kconfig/merge_config.sh -m $(KERNEL_CONFIG) && mv -f .config $(KERNEL_OUT)/.merged.config && $(MAKE) -j1 $(KERNEL_VERBOSE) O=$(KERNEL_OUT) ARCH=arm KCONFIG_ALLCONFIG=$(KERNEL_OUT)/.merged.config alldefconfig; \
	else $(MAKE) -j1 KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" $(KERNEL_VERBOSE) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) LD=$$LD defconfig $(KERNEL_CONFIG); \
	fi && \
	$(MAKE) $(KERNEL_VERBOSE) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" LD=$$LD $(KERNEL_TARGET) 
ifeq ($(INCLUDE_PERF),1)
	cd $(TOP)/kernel/tools/perf &&\
	mkdir -p $(KERNEL_OUT)/tools/perf &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	export PATH=../$(BUILD_OUT_EXECUTABLES):$(PATH) && \
	$(MAKE) EXTRA_CFLAGS="$(TARGET_EXTRA_CFLAGS) $(LOCAL_CFLAGS) -isystem $(REALTOP)/bionic/libc/include -isystem $(REALTOP)/bionic/libc/kernel/common -isystem $(REALTOP)/bionic/libc/kernel/arch-arm -isystem $(REALTOP)/bionic/libc/arch-arm/include -I$(REALTOP)/external/elfutils/libelf -isystem $(REALTOP)/bionic/libm/include -isystem $(shell dirname $(KERNEL_TOOLS_PREFIX))/../include -I$(KERNEL_OUT)/tools/perf" BASIC_LDFLAGS="-nostdlib -Wl,-dynamic-linker,/system/bin/linker,-z,muldefs$(shell if test $(PLATFORM_SDK_VERSION) -lt 16; then echo -ne ',-T$(REALTOP)/$(BUILD_SYSTEM)/armelf.x'; fi),-z,nocopyreloc,--no-undefined -L$(REALTOP)/$(TARGET_OUT_STATIC_LIBRARIES) -L$(REALTOP)/$(PRODUCT_OUT)/system/lib -L$(REALTOP)/external/elfutils -L$(realpath $(PRODUCT_OUT))/obj/STATIC_LIBRARIES/libelf_intermediates -lpthread -lelf -lm -lc $(REALTOP)/$(TARGET_CRTBEGIN_DYNAMIC_O) $(REALTOP)/$(TARGET_CRTEND_O)" $(KERNEL_VERBOSE) O=$(KERNEL_OUT)/tools/perf/ OUTPUT=$(KERNEL_OUT)/tools/perf/ ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) LD=$$LD prefix=/system NO_DWARF=1 NO_NEWT=1 NO_LIBPERL=1 NO_LIBPYTHON=1 NO_GTK2=1 NO_STRLCPY=1 WERROR=0 && \
	cp -f $(KERNEL_OUT)/tools/perf/perf $(REALTOP)/$(PRODUCT_OUT)/system/bin/
endif

android_kernel_modules: $(INSTALLED_KERNEL_TARGET) $(ACP)
	cd $(TOP)/kernel &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	export PATH=../$(BUILD_OUT_EXECUTABLES):$(PATH) && \
	$(MAKE) $(KERNEL_VERBOSE) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) LD=$$LD EXTRA_CFLAGS="$(EXTRA_CFLAGS) -fno-pic" KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" modules
	mkdir -p $(KERNEL_OUT)/modules_for_android
	cd $(TOP)/kernel &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	$(MAKE) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" LD=$$LD modules_install INSTALL_MOD_PATH=$(KERNEL_OUT)/modules_for_android
	mkdir -p $(TARGET_OUT)/modules
	find $(KERNEL_OUT)/modules_for_android -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_OUT)/modules/ \;

#NOTE: the gator driver's Makefile wasn't done properly and doesn't put build
#      artifacts in the O=$(KERNEL_OUT)
ifeq ($(TARGET_USE_GATOR),true)

KERNEL_PATH:=$(shell pwd)/kernel

ifneq ($(TARGET_GATOR_WITH_MALI_SUPPORT),)
ifndef TARGET_MALI_DRIVER_DIR
$(error TARGET_MALI_DRIVER_DIR must be defined if TARGET_GATOR_WITH_MALI_SUPPORT is.)
endif
GATOR_EXTRA_CFLAGS += -DMALI_SUPPORT=$(TARGET_GATOR_WITH_MALI_SUPPORT) -I$(KERNEL_PATH)/$(TARGET_MALI_DRIVER_DIR)
GATOR_EXTRA_MAKE_ARGS += GATOR_WITH_MALI_SUPPORT=$(TARGET_GATOR_WITH_MALI_SUPPORT)
endif

ifneq ($(realpath $(TOP)/external/gator/driver),)
gator_driver: android_kernel_modules $(INSTALLED_KERNEL_TARGET) $(ACP)
	cd $(TOP)/external/gator/driver &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	export PATH=../$(BUILD_OUT_EXECUTABLES):$(PATH) && \
	$(MAKE) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) LD=$$LD EXTRA_CFLAGS="$(EXTRA_CFLAGS) -fno-pic $(GATOR_EXTRA_CFLAGS)" KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" $(GATOR_EXTRA_MAKE_ARGS) -C $(KERNEL_PATH) M=`pwd` modules
	mkdir -p $(TARGET_OUT)/modules
	find $(TOP)/external/gator/driver/. -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_OUT)/modules/ \;
else
gator_driver:
endif

else
gator_driver:
endif

out_of_tree_modules: $(INSTALLED_KERNEL_TARGET) gator_driver

$(INSTALLED_KERNEL_TARGET): android_kernel
	ln -sf $(KERNEL_OUT)/arch/arm/boot/$(KERNEL_TARGET) $(INSTALLED_KERNEL_TARGET)

$(INSTALLED_SYSTEMTARBALL_TARGET): android_kernel_modules out_of_tree_modules


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

$(1): $$(INSTALLED_KERNEL_TARGET) $$(ACP)
	cd $$(TOP)/kernel && \
	export PATH=../$$(BUILD_OUT_EXECUTABLES):$$(PATH) && \
	$$(MAKE) O=$$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$$(KERNEL_TOOLS_PREFIX) $2.dtb
	@mkdir -p $$(dir $$@)
	$$(ACP) -fpt $$(KERNEL_OUT)/arch/arm/boot/$2.dtb $$@

endef

#
# DEVICE_TREES contains a list of device-trees to build, each
# entry in the list is in the form <source-name>:<blob-name>
#
DEVICE_TREE_TARGETS :=
$(foreach _ub,$(DEVICE_TREES),                             \
    $(eval _source := $(call word-colon,1,$(_ub)))         \
    $(eval _blob := $(call word-colon,2,$(_ub)))           \
    $(eval _target := $(PRODUCT_OUT)/boot/$(_blob))        \
    $(eval $(call MAKE_DEVICE_TREE,$(_target),$(_source))) \
    $(eval DEVICE_TREE_TARGETS += $(_target))              \
    )

$(INSTALLED_BOOTTARBALL_TARGET): $(DEVICE_TREE_TARGETS)

ifeq ($(TARGET_PRODUCT), vexpress_rtsm)
bootwrapper: $(DEVICE_TREE_TARGETS)
endif

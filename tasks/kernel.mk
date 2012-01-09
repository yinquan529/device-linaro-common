ifneq ($(strip $(SHOW_COMMANDS)),)
KERNEL_VERBOSE="V=1"
endif

ifneq ($(findstring prebuilt,$(TARGET_TOOLS_PREFIX)),)
# The prebuilt toolchain is way too old to compile
# current kernels - so we use a system wide toolchain
# installation if available.
KERNEL_TOOLS_PREFIX ?= $(shell which arm-linux-gnueabi-gcc |sed -e 's,gcc,,')
else
KERNEL_TOOLS_PREFIX ?= $(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX))
endif

LOCAL_CFLAGS=$(call cc-option,"-mno-unaligned-access", )

ODIR=$(shell readlink -f $(PRODUCT_OUT)/obj/kernel)

android_kernel: $(PRODUCT_OUT)/u-boot.bin
	mkdir -p $(ODIR)
	cd $(TOP)/kernel &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	export PATH=../$(BUILD_OUT_EXECUTABLES):$(PATH) && \
	$(MAKE) -j1 KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" $(KERNEL_VERBOSE) O=$(ODIR) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) LD=$$LD defconfig $(KERNEL_CONFIG) &&\
	$(MAKE) $(KERNEL_VERBOSE) O=$(ODIR) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" LD=$$LD uImage

android_kernel_modules: $(INSTALLED_KERNEL_TARGET) $(ACP)
	cd $(TOP)/kernel &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	export PATH=../$(BUILD_OUT_EXECUTABLES):$(PATH) && \
	$(MAKE) O=$(ODIR) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) LD=$$LD EXTRA_CFLAGS="$(EXTRA_CFLAGS) -fno-pic" KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" modules
	mkdir -p $(ODIR)/modules_for_android
	cd $(TOP)/kernel &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	$(MAKE) O=$(ODIR) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" LD=$$LD modules_install INSTALL_MOD_PATH=$(ODIR)/modules_for_android
	mkdir -p $(TARGET_OUT)/modules
	find $(ODIR)/modules_for_android -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_OUT)/modules/ \;

#NOTE: the gator driver's Makefile wasn't done properly and doesn't put build
#      artifacts in the O=$(ODIR)
ifeq ($(TARGET_USE_GATOR),true)
KERNEL_PATH:=$(shell pwd)/kernel
gator_driver: android_kernel_modules $(INSTALLED_KERNEL_TARGET) $(ACP)
	cd $(TOP)/external/gator/driver &&\
	if [ -e $(KERNEL_TOOLS_PREFIX)ld.bfd ]; then LD=$(KERNEL_TOOLS_PREFIX)ld.bfd; else LD=$(KERNEL_TOOLS_PREFIX)ld; fi && \
	export PATH=../$(BUILD_OUT_EXECUTABLES):$(PATH) && \
	$(MAKE) O=$(ODIR) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) LD=$$LD EXTRA_CFLAGS="$(EXTRA_CFLAGS) -fno-pic" KCFLAGS="$(TARGET_EXTRA_CFLAGS) -fno-pic $(LOCAL_CFLAGS)" -C $(KERNEL_PATH) M=`pwd` modules
	mkdir -p $(TARGET_OUT)/modules
	find $(TOP)/external/gator/driver/. -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_OUT)/modules/ \;
else
gator_driver:
endif

out_of_tree_modules: $(INSTALLED_KERNEL_TARGET) gator_driver

$(INSTALLED_KERNEL_TARGET): android_kernel
	ln -sf $(ODIR)/arch/arm/boot/uImage $(INSTALLED_KERNEL_TARGET)

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
	$$(MAKE) O=$$(ODIR) ARCH=arm CROSS_COMPILE=$$(KERNEL_TOOLS_PREFIX) $2.dtb
	@mkdir -p $$(dir $$@)
	$$(ACP) -fpt $$(ODIR)/arch/arm/boot/$2.dtb $$@

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

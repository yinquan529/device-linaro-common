ifneq ($(UBOOT_TOOLS_PREFIX),)
UBOOT_TCDIR = $(realpath $(shell dirname $(UBOOT_TOOLS_PREFIX)))
UBOOT_TCPREFIX = $(shell basename $(UBOOT_TOOLS_PREFIX))
else
UBOOT_TCDIR = $(realpath $(shell dirname $(TARGET_TOOLS_PREFIX)))
# u-boot is not an Android application and should be
# built with the bare metal toolchain if it is available
UBOOT_TCPREFIX = $(shell if [ -e $(UBOOT_TCDIR)/arm-eabi-gcc ]; then echo arm-eabi-; else basename $(TARGET_TOOLS_PREFIX); fi)
endif

# Set source path for u-boot
# 1. use TARGET_UBOOT_SOURCE if defined
# 2. try to use u-boot/<vendor>/<device> if it exists
# 3. try to use u-boot (done in the android_uboot rule)
TARGET_AUTO_UDIR := $(shell echo $(TARGET_DEVICE_DIR) | sed -e 's/^device/u-boot/g')
TARGET_UBOOT_SOURCE ?= $(shell if [ -e $(TARGET_AUTO_UDIR) ]; then echo $(TARGET_AUTO_UDIR); else echo u-boot; fi;)
UBOOT_SRC := $(TARGET_UBOOT_SOURCE)

ifeq ($(TARGET_USE_UBOOT), true)

ifeq ($(USE_PREBUILT_UBOOT),)
USE_PREBUILT_UBOOT=false
endif

ifeq ($(USE_PREBUILT_UBOOT), false)
# u-boot can't be built with gold - so we force BFD LD into the
# PATH ahead of everything else
android_uboot: $(ACP)
	$(eval UBOOT_FOREST_ROOT:=$(CURDIR))
	mkdir -p $(PRODUCT_OUT)/obj/u-boot
ifeq ($(TARGET_PRODUCT), origen_quad)
	if [ -e $(TOP)/vendor/insignal/origen_quad/exynos4x12/exynos4x12.bl1.bin ]; then \
		mkdir -p $(TOP)/u-boot/firmware/origen_quad; \
		cp $(TOP)/vendor/insignal/origen_quad/exynos4x12/exynos4x12.bl1.bin $(TOP)/$(UBOOT_SRC)/firmware/origen_quad/bl1.fw; \
	fi
endif
	cd $(UBOOT_SRC) &&\
	if [ -e $(UBOOT_TCDIR)/$(UBOOT_TCPREFIX)ld.bfd ]; then ln -sf $(UBOOT_TCDIR)/$(UBOOT_TCPREFIX)ld.bfd $(UBOOT_TCPREFIX)ld; fi &&\
	export PATH=`pwd`:$(UBOOT_TCDIR):$(PATH) && \
	$(MAKE) O=$(UBOOT_FOREST_ROOT)/$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=$(UBOOT_TCPREFIX) $(UBOOT_CONFIG) &&\
	$(MAKE) O=$(UBOOT_FOREST_ROOT)/$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=$(UBOOT_TCPREFIX)
ifeq ($(TARGET_PRODUCT), iMX53)
	cd $(UBOOT_SRC) &&\
	export PATH=`pwd`:$(UBOOT_TCDIR):$(PATH) && \
	$(MAKE) CROSS_COMPILE=$(UBOOT_TCPREFIX) $(UBOOT_CONFIG) && \
	$(MAKE) CROSS_COMPILE=$(UBOOT_TCPREFIX) u-boot.imx
endif
ifeq ($(TARGET_PRODUCT), iMX6)
	cd $(UBOOT_SRC) &&\
	export PATH=`pwd`:$(UBOOT_TCDIR):$(PATH) && \
	$(MAKE) CROSS_COMPILE=$(UBOOT_TCPREFIX) $(UBOOT_CONFIG) && \
	$(MAKE) CROSS_COMPILE=$(UBOOT_TCPREFIX) u-boot.imx
endif
	cd $(TOP) && $(ACP) -fept $(PRODUCT_OUT)/obj/u-boot/tools/mkimage $(BUILD_OUT_EXECUTABLES)/

$(PRODUCT_OUT)/u-boot.bin: android_uboot
	ln -sf obj/u-boot/u-boot.bin $(PRODUCT_OUT)/u-boot.bin
ifeq ($(TARGET_PRODUCT), iMX53)
	cp $(UBOOT_SRC)/u-boot.imx $(PRODUCT_OUT)/u-boot.imx
endif
ifeq ($(TARGET_PRODUCT), iMX6)
	cp $(UBOOT_SRC)/u-boot.imx $(PRODUCT_OUT)/u-boot.imx
endif
ifeq ($(TARGET_PRODUCT), origen)
	mkdir -p $(PRODUCT_OUT)/boot
	cp $(PRODUCT_OUT)/obj/u-boot/spl/origen-spl.bin $(PRODUCT_OUT)/boot/u-boot-mmc-spl.bin
endif
ifeq ($(TARGET_PRODUCT), origen_quad)
	mkdir -p $(PRODUCT_OUT)/boot
	cp $(PRODUCT_OUT)/obj/u-boot/spl/origen_quad-spl.bin $(PRODUCT_OUT)/boot/u-boot-mmc-spl.bin
endif
ifeq ($(TARGET_PRODUCT), full_arndale)
	mkdir -p $(PRODUCT_OUT)/boot
	cp $(PRODUCT_OUT)/obj/u-boot/spl/smdk5250-spl.bin $(PRODUCT_OUT)/boot/u-boot-mmc-spl.bin
endif
endif

ifneq (,$(filter $(TARGET_PRODUCT),pandaboard panda5))
ifeq ($(USE_PREBUILT_UBOOT), true)
$(PRODUCT_OUT)/u-boot.bin:
	ln -sf ../../../../device/linaro/pandaboard/u-boot.bin $(PRODUCT_OUT)/u-boot.bin
$(PRODUCT_OUT)/u-boot.img:
	ln -sf ../../../../device/linaro/pandaboard/u-boot.bin $(PRODUCT_OUT)/u-boot.img

$(PRODUCT_OUT)/MLO:
	ln -sf ../../../../device/linaro/pandaboard/MLO $(PRODUCT_OUT)/MLO
else
$(PRODUCT_OUT)/u-boot.img: android_uboot
	ln -sf obj/u-boot/u-boot.img $(PRODUCT_OUT)/u-boot.img

$(PRODUCT_OUT)/MLO: android_uboot
	ln -sf obj/u-boot/MLO $(PRODUCT_OUT)/MLO
endif
endif

ifeq ($(TARGET_PRODUCT), full_panda)
ifeq ($(USE_PREBUILT_UBOOT), true)
$(PRODUCT_OUT)/u-boot.bin:
	ln -sf ../../../../device/ti/panda/u-boot.bin $(PRODUCT_OUT)/u-boot.bin
$(PRODUCT_OUT)/u-boot.img:
	ln -sf ../../../../device/ti/panda/u-boot.bin $(PRODUCT_OUT)/u-boot.img

$(PRODUCT_OUT)/MLO:
	ln -sf ../../../../device/ti/panda/MLO $(PRODUCT_OUT)/MLO
else
$(PRODUCT_OUT)/u-boot.img: android_uboot
	ln -sf obj/u-boot/u-boot.img $(PRODUCT_OUT)/u-boot.img

$(PRODUCT_OUT)/MLO: android_uboot
	ln -sf obj/u-boot/MLO $(PRODUCT_OUT)/MLO
endif
endif
else
$(PRODUCT_OUT)/u-boot.bin:
endif

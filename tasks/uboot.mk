ifeq ($(TARGET_USE_UBOOT), true)
ifneq ($(UBOOT_TOOLS_PREFIX),)
UBOOT_TCDIR = $(realpath $(shell dirname $(UBOOT_TOOLS_PREFIX)))
UBOOT_TCPREFIX = $(shell basename $(UBOOT_TOOLS_PREFIX))
else
ifneq ($(findstring prebuilt,$(TARGET_TOOLS_PREFIX)),)
# The AOSP prebuilt toolchain is too old to compile
# current u-boot, so we fall back to a system compiler
UBOOT_TCDIR = $(shell basename `which arm-linux-gnueabi-gcc`)
UBOOT_TCPREFIX = arm-linux-gnueabi-
else
UBOOT_TCDIR = $(realpath $(shell dirname $(TARGET_TOOLS_PREFIX)))
# u-boot is not an Android application and should be
# built with the bare metal toolchain if it is available
UBOOT_TCPREFIX = $(shell if [ -e $(UBOOT_TCDIR)/arm-eabi-gcc ]; then echo arm-eabi-; else basename $(TARGET_TOOLS_PREFIX); fi)
endif
endif


ifeq ($(USE_PREBUILT_UBOOT),)
USE_PREBUILT_UBOOT=false
endif

ifeq ($(USE_PREBUILT_UBOOT), false)
# u-boot can't be built with gold - so we force BFD LD into the
# PATH ahead of everything else
android_uboot: $(ACP)
	mkdir -p $(PRODUCT_OUT)/obj/u-boot
	cd $(TOP)/u-boot &&\
	if [ -e $(UBOOT_TCDIR)/$(UBOOT_TCPREFIX)ld.bfd ]; then ln -sf $(UBOOT_TCDIR)/$(UBOOT_TCPREFIX)ld.bfd $(UBOOT_TCPREFIX)ld; fi &&\
	export PATH=`pwd`:$(UBOOT_TCDIR):$(PATH) && \
	$(MAKE) O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=$(UBOOT_TCPREFIX) $(UBOOT_CONFIG) &&\
	$(MAKE) O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=$(UBOOT_TCPREFIX)
ifeq ($(TARGET_PRODUCT), iMX53)
	cd $(TOP)/u-boot &&\
	export PATH=`pwd`:$(UBOOT_TCDIR):$(PATH) && \
	$(MAKE) CROSS_COMPILE=$(UBOOT_TCPREFIX) $(UBOOT_CONFIG) && \
	$(MAKE) CROSS_COMPILE=$(UBOOT_TCPREFIX) u-boot.imx
endif
ifeq ($(TARGET_PRODUCT), iMX6)
	cd $(TOP)/u-boot &&\
	export PATH=`pwd`:$(UBOOT_TCDIR):$(PATH) && \
	$(MAKE) CROSS_COMPILE=$(UBOOT_TCPREFIX) $(UBOOT_CONFIG) && \
	$(MAKE) CROSS_COMPILE=$(UBOOT_TCPREFIX) u-boot.imx
endif
	cd $(TOP) && $(ACP) -fept $(PRODUCT_OUT)/obj/u-boot/tools/mkimage $(BUILD_OUT_EXECUTABLES)/

$(PRODUCT_OUT)/u-boot.bin: android_uboot
	ln -sf obj/u-boot/u-boot.bin $(PRODUCT_OUT)/u-boot.bin
ifeq ($(TARGET_PRODUCT), iMX53)
	cp $(TOP)/u-boot/u-boot.imx $(PRODUCT_OUT)/u-boot.imx
endif
ifeq ($(TARGET_PRODUCT), iMX6)
	cp $(TOP)/u-boot/u-boot.imx $(PRODUCT_OUT)/u-boot.imx
endif
ifeq ($(TARGET_PRODUCT), origen)
	mkdir -p $(PRODUCT_OUT)/boot
	cp $(PRODUCT_OUT)/obj/u-boot/spl/origen-spl.bin $(PRODUCT_OUT)/boot/u-boot-mmc-spl.bin
endif
endif

ifeq ($(TARGET_PRODUCT), origen_quad)
ifeq ($(USE_PREBUILT_UBOOT), true)
$(PRODUCT_OUT)/u-boot.bin:
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

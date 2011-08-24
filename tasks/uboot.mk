TCPREFIX = arm-linux-gnueabi-
# The 2 lines below (instead of the one above) are actually the right
# thing to do -- grabbing the toolchain we're meant to use.
# Unfortunately the current (4.6-2011.07-0-8-2011-07-25_12-42-06-linux-x86)
# ld fails to link u-boot, so we revert to the old behavior (since it
# picks up an older, working ld on the build machines) for now.
#TCDIR = $(shell dirname $(TARGET_TOOLS_PREFIX))
#TCPREFIX = $(shell basename $(TARGET_TOOLS_PREFIX))

android_uboot:
	mkdir -p $(PRODUCT_OUT)/obj/u-boot
	cd $(TOP)/u-boot &&\
	export PATH=$(TCDIR):$(PATH) && \
	make O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=$(TCPREFIX) $(UBOOT_CONFIG) &&\
	make O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=$(TCPREFIX)
ifeq ($(TARGET_PRODUCT), iMX53)
	cd $(TOP)/u-boot &&\
	export PATH=$(TCDIR):$(PATH) && \
	make CROSS_COMPILE=$(TCPREFIX) $(UBOOT_CONFIG) && \
	make CROSS_COMPILE=$(TCPREFIX) u-boot.imx
endif

$(PRODUCT_OUT)/u-boot.bin: android_uboot
	ln -sf obj/u-boot/u-boot.bin $(PRODUCT_OUT)/u-boot.bin
ifeq ($(TARGET_PRODUCT), iMX53)
	cp $(TOP)/u-boot/u-boot.imx $(PRODUCT_OUT)/u-boot.imx
endif
ifeq ($(TARGET_PRODUCT), origen)
	mkdir -p $(PRODUCT_OUT)/boot
	cp $(PRODUCT_OUT)/obj/u-boot/mmc_spl/u-boot-mmc-spl.bin $(PRODUCT_OUT)/boot/u-boot-mmc-spl.bin
endif

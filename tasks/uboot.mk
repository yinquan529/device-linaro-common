TCDIR = $(shell dirname $(TARGET_TOOLS_PREFIX))
TCPREFIX = $(shell basename $(TARGET_TOOLS_PREFIX))

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


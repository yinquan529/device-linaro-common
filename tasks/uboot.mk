android_uboot:
	mkdir -p $(PRODUCT_OUT)/obj/u-boot
	cd $(TOP)/u-boot &&\
	make O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=arm-linux-gnueabi- $(UBOOT_CONFIG) &&\
	make O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=arm-linux-gnueabi- 
ifeq ($(TARGET_PRODUCT), iMX53)
	make CROSS_COMPILE=arm-linux-gnueabi- $(UBOOT_CONFIG) && make CROSS_COMPILE=arm-linux-gnueabi- u-boot.imx
endif

$(PRODUCT_OUT)/u-boot.bin: android_uboot
	ln -sf obj/u-boot/u-boot.bin $(PRODUCT_OUT)/u-boot.bin
ifeq ($(TARGET_PRODUCT), iMX53)
	cp u-boot.imx $(PRODUCT_OUT)/u-boot.imx
endif


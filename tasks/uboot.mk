android_uboot:
	rm -fr $(PRODUCT_OUT)/obj/u-boot
	mkdir $(PRODUCT_OUT)/obj/u-boot
	cd $(TOP)/u-boot &&\
	make O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=arm-linux-gnueabi- $(UBOOT_CONFIG) &&\
	make O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=arm-linux-gnueabi- 

$(PRODUCT_OUT)/u-boot.bin: android_uboot
	ln -sf obj/u-boot/u-boot.bin $(PRODUCT_OUT)/u-boot.bin


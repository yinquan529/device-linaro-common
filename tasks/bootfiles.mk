
ifeq ($(TARGET_USE_UBOOT),true)
bootfiles: $(PRODUCT_OUT)/u-boot.bin 
endif

bootfiles:
	$(hide) mkdir -p $(PRODUCT_OUT)/boot
ifeq ($(TARGET_USE_UBOOT),true)
	cp $(PRODUCT_OUT)/u-boot.bin $(PRODUCT_OUT)/boot
endif
ifeq ($(TARGET_USE_XLOADER),true)
	cp $(XLOADER_BINARY) $(PRODUCT_OUT)/boot
endif

$(INSTALLED_BOOTTARBALL_TARGET): bootfiles
.PHONY: u-boot-img mlo
ifneq (,$(filter $(TARGET_PRODUCT), pandaboard panda5 full_panda))
u-boot-img: $(PRODUCT_OUT)/u-boot.img
mlo: $(PRODUCT_OUT)/MLO
else
u-boot-img:
mlo:
endif

.PHONY: u-boot
ifeq ($(TARGET_USE_UBOOT),true)
u-boot: $(PRODUCT_OUT)/u-boot.bin
else
u-boot: 
endif

.PHONY: xloader-config
.PHONY:	x-loader
.PHONY: cleanup
ifeq ($(TARGET_USE_XLOADER),true)
cleanup:
	cd $(TOP)/device/linaro/x-loader &&\
	make mrproper

xloader-config: cleanup
	cd $(TOP)/device/linaro/x-loader &&\
	make $(XLOADER_CONFIG)

x-loader: xloader-config
	cd $(TOP)/device/linaro/x-loader &&\
	make ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) all
else
xloader-config:
x-loader:
endif

.PHONY:	copybootfiles
copybootfiles:	x-loader u-boot u-boot-img mlo
	$(hide) mkdir -p $(PRODUCT_OUT)/boot
ifneq (,$(filter $(TARGET_PRODUCT), pandaboard panda5))
	cp $(PRODUCT_OUT)/u-boot.img $(PRODUCT_OUT)/boot
	cp $(PRODUCT_OUT)/MLO $(PRODUCT_OUT)/boot
endif
ifeq ($(TARGET_PRODUCT), full_panda)
	cp $(PRODUCT_OUT)/u-boot.img $(PRODUCT_OUT)/boot
	cp $(PRODUCT_OUT)/MLO $(PRODUCT_OUT)/boot
endif
ifeq ($(TARGET_USE_UBOOT),true)
	cp $(PRODUCT_OUT)/u-boot.bin $(PRODUCT_OUT)/boot
ifeq ($(TARGET_PRODUCT), iMX53)
	cp -L $(PRODUCT_OUT)/u-boot.imx $(PRODUCT_OUT)/boot
endif
ifeq ($(TARGET_PRODUCT), iMX6)
	cp -L $(PRODUCT_OUT)/u-boot.imx $(PRODUCT_OUT)/boot
endif
endif
ifeq ($(TARGET_USE_XLOADER),true)
	cp $(TOP)/device/linaro/x-loader/MLO $(PRODUCT_OUT)/boot
endif
ifneq ($(TARGET_HWPACK_CONFIG),)
	cp $(TARGET_HWPACK_CONFIG) $(PRODUCT_OUT)/boot/config
endif
ifeq ($(TARGET_BOARD_PLATFORM),origen_quad)
	cp -r $(TOP)/vendor/samsung/origen_quad/proprietary/bootloader/* $(PRODUCT_OUT)/boot
	cp -r $(TOP)/vendor/samsung/origen_quad/proprietary/EULA.txt $(PRODUCT_OUT)/boot
endif
ifeq ($(TARGET_BOARD_PLATFORM),arndale)
	cp -r $(TOP)/device/linaro/arndale/arndale-bl1.bin $(PRODUCT_OUT)/boot
endif
ifeq ($(TARGET_BOARD_PLATFORM),arndale_octa)
	cp -r $(TOP)/device/linaro/arndale_octa/arndale-octa.bl1.bin $(PRODUCT_OUT)/boot
	cp -r $(TOP)/device/linaro/arndale_octa/arndale-octa.tzsw.bin $(PRODUCT_OUT)/boot
	cp -r $(TOP)/device/linaro/arndale_octa/smdk5420-spl.signed.bin $(PRODUCT_OUT)/boot
endif
ifeq ($(ANDROID_64),true)
	cp -r $(TOP)/fvp-pre-boot/*.bin $(PRODUCT_OUT)/boot
endif

$(INSTALLED_BOOTTARBALL_TARGET): copybootfiles


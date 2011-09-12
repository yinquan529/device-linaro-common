UBOOT_TCDIR = $(shell dirname $(TARGET_TOOLS_PREFIX))
UBOOT_TCPREFIX = $(shell basename $(TARGET_TOOLS_PREFIX))

# u-boot tends to trigger compiler and linker bugs frequently.
# If you're running into a problem not fixed easily, use an
# older compiler by commenting out the 2 lines above and
# uncommenting the one below.
#UBOOT_TCPREFIX = arm-linux-gnueabi-

android_uboot:
	mkdir -p $(PRODUCT_OUT)/obj/u-boot
	cd $(TOP)/u-boot &&\
	export PATH=$(UBOOT_TCDIR):$(PATH) && \
	make O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=$(UBOOT_TCPREFIX) $(UBOOT_CONFIG) &&\
	make O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=$(UBOOT_TCPREFIX)
ifeq ($(TARGET_PRODUCT), iMX53)
	cd $(TOP)/u-boot &&\
	export PATH=$(UBOOT_TCDIR):$(PATH) && \
	make CROSS_COMPILE=$(UBOOT_TCPREFIX) $(UBOOT_CONFIG) && \
	make CROSS_COMPILE=$(UBOOT_TCPREFIX) u-boot.imx
endif

$(PRODUCT_OUT)/u-boot.bin: android_uboot
	ln -sf obj/u-boot/u-boot.bin $(PRODUCT_OUT)/u-boot.bin
ifeq ($(TARGET_PRODUCT), iMX53)
	cp $(TOP)/u-boot/u-boot.imx $(PRODUCT_OUT)/u-boot.imx
endif
ifeq ($(TARGET_PRODUCT), origen)
	mkdir -p $(PRODUCT_OUT)/boot
	cp $(PRODUCT_OUT)/obj/u-boot/spl/origen-spl.bin $(PRODUCT_OUT)/boot/u-boot-mmc-spl.bin
endif


ifeq ($(TARGET_PRODUCT), pandaboard)
$(PRODUCT_OUT)/u-boot.img: android_uboot
	ln -sf obj/u-boot/u-boot.img $(PRODUCT_OUT)/u-boot.img

$(PRODUCT_OUT)/MLO: android_uboot
	ln -sf obj/u-boot/MLO $(PRODUCT_OUT)/MLO
endif

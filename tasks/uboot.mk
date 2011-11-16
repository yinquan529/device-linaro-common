UBOOT_TCDIR = $(shell dirname $(TARGET_TOOLS_PREFIX))
UBOOT_TCPREFIX = $(shell basename $(TARGET_TOOLS_PREFIX))

# u-boot tends to trigger compiler and linker bugs frequently.
# If you're running into a problem not fixed easily, use an
# older compiler by commenting out the 2 lines above and
# uncommenting the one below.
#UBOOT_TCPREFIX = arm-linux-gnueabi-

# u-boot can't be built with gold - so we force BFD LD into the
# PATH ahead of everything else

android_uboot: $(ACP)
	mkdir -p $(PRODUCT_OUT)/obj/u-boot
	cd $(TOP)/u-boot &&\
	if [ -e $(UBOOT_TCDIR)/$(UBOOT_TCPREFIX)ld.bfd ]; then ln -sf $(UBOOT_TCDIR)/$(UBOOT_TCPREFIX)ld.bfd $(UBOOT_TCPREFIX)ld; ln -sf $(UBOOT_TCDIR)/$(UBOOT_TCPREFIX)ld.bfd ld; fi &&\
	export PATH=`pwd`:$(UBOOT_TCDIR):$(PATH) && \
	$(MAKE) O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=$(UBOOT_TCPREFIX) $(UBOOT_CONFIG) &&\
	$(MAKE) O=../$(PRODUCT_OUT)/obj/u-boot CROSS_COMPILE=$(UBOOT_TCPREFIX)
ifeq ($(TARGET_PRODUCT), iMX53)
	cd $(TOP)/u-boot &&\
	export PATH=$(UBOOT_TCDIR):$(PATH) && \
	$(MAKE) CROSS_COMPILE=$(UBOOT_TCPREFIX) $(UBOOT_CONFIG) && \
	$(MAKE) CROSS_COMPILE=$(UBOOT_TCPREFIX) u-boot.imx
endif
	cd $(TOP) && $(ACP) -fept $(PRODUCT_OUT)/obj/u-boot/tools/mkimage $(BUILD_OUT_EXECUTABLES)/

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
ifeq ($(TARGET_PRODUCT), panda)
$(PRODUCT_OUT)/u-boot.img: android_uboot
	ln -sf obj/u-boot/u-boot.img $(PRODUCT_OUT)/u-boot.img

$(PRODUCT_OUT)/MLO: android_uboot
	ln -sf obj/u-boot/MLO $(PRODUCT_OUT)/MLO
endif

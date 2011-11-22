ifneq ($(strip $(SHOW_COMMANDS)),)
KERNEL_VERBOSE="V=1"
endif

android_kernel: $(PRODUCT_OUT)/u-boot.bin
	cd $(TOP)/kernel &&\
	$(MAKE) -j1 $(KERNEL_VERBOSE) ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- defconfig $(KERNEL_CONFIG) &&\
	$(MAKE) $(KERNEL_VERBOSE) ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- uImage

android_kernel_modules: $(INSTALLED_KERNEL_TARGET) $(ACP)
	cd $(TOP)/kernel &&\
	$(MAKE) ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- modules
	mkdir -p $(TOP)/kernel/modules_for_android
	cd $(TOP)/kernel &&\
	$(MAKE) ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- modules_install INSTALL_MOD_PATH=modules_for_android
	mkdir -p $(TARGET_OUT)/modules
	find kernel/modules_for_android -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_OUT)/modules/ \;


ifeq ($(TARGET_USE_GATOR),true)
KERNEL_PATH:=$(shell pwd)/kernel
gator_driver: android_kernel_modules $(INSTALLED_KERNEL_TARGET) $(ACP)
	cd $(TOP)/external/gator/driver &&\
	$(MAKE) ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -C $(KERNEL_PATH) M=`pwd` modules
	mkdir -p $(TARGET_OUT)/modules
	find $(TOP)/external/gator/driver/. -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_OUT)/modules/ \;
else
gator_driver:
endif

out_of_tree_modules: $(INSTALLED_KERNEL_TARGET) gator_driver

$(INSTALLED_KERNEL_TARGET): android_kernel
	ln -sf ../../../../kernel/arch/arm/boot/uImage $(INSTALLED_KERNEL_TARGET)

$(INSTALLED_SYSTEMTARBALL_TARGET): android_kernel_modules out_of_tree_modules

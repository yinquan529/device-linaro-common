android_kernel:
	cd $(TOP)/kernel &&\
	$(MAKE) -j1 ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) defconfig $(KERNEL_CONFIG) &&\
	$(MAKE) ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) uImage

android_kernel_modules: $(PRODUCT_OUT)/uImage $(ACP)
	cd $(TOP)/kernel &&\
	$(MAKE) ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) modules
	mkdir -p $(TOP)/kernel/modules_for_android
	cd $(TOP)/kernel &&\
	$(MAKE) ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) modules_install INSTALL_MOD_PATH=modules_for_android
	mkdir -p $(TARGET_OUT)/modules
	find kernel/modules_for_android -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_OUT)/modules/ \;


ifeq ($(TARGET_USE_GATOR),true)
KERNEL_PATH:=$(shell pwd)/kernel
gator_driver: $(ACP)
	cd $(TOP)/external/gator/driver &&\
	$(MAKE) ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) -C $(KERNEL_PATH) M=`pwd` modules
	mkdir -p $(TARGET_OUT)/modules
	find . -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_OUT)/modules/ \;
else
gator_driver:
endif

out_of_tree_modules: $(PRODUCT_OUT)/uImage gator_driver

$(PRODUCT_OUT)/uImage: android_kernel
	ln -sf ../../../../kernel/arch/arm/boot/uImage $(PRODUCT_OUT)/uImage

$(INSTALLED_SYSTEMTARBALL_TARGET): android_kernel_modules out_of_tree_modules

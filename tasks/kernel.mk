android_kernel: $(PRODUCT_OUT)/u-boot.bin
	cd $(TOP)/kernel &&\
	if [ -e $(TARGET_TOOLS_PREFIX)ld.bfd ]; then LD=$(TARGET_TOOLS_PREFIX)ld.bfd; else LD=$(TARGET_TOOLS_PREFIX)ld; fi && \
	export PATH=../$(BUILD_OUT_EXECUTABLES):$(PATH) && \
	$(MAKE) V=1 -j1 ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) LD=$$LD defconfig $(KERNEL_CONFIG) &&\
	$(MAKE) V=1 ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) LD=$$LD uImage

android_kernel_modules: $(INSTALLED_KERNEL_TARGET) $(ACP)
	cd $(TOP)/kernel &&\
	export PATH=../$(BUILD_OUT_EXECUTABLES):$(PATH) && \
	$(MAKE) ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) modules
	mkdir -p $(TOP)/kernel/modules_for_android
	cd $(TOP)/kernel &&\
	$(MAKE) ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) modules_install INSTALL_MOD_PATH=modules_for_android
	mkdir -p $(TARGET_OUT)/modules
	find kernel/modules_for_android -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_OUT)/modules/ \;


ifeq ($(TARGET_USE_GATOR),true)
KERNEL_PATH:=$(shell pwd)/kernel
gator_driver: android_kernel_modules $(INSTALLED_KERNEL_TARGET) $(ACP)
	cd $(TOP)/external/gator/driver &&\
	$(MAKE) ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) -C $(KERNEL_PATH) M=`pwd` modules
	mkdir -p $(TARGET_OUT)/modules
	find $(TOP)/external/gator/driver/. -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_OUT)/modules/ \;
else
gator_driver:
endif

out_of_tree_modules: $(INSTALLED_KERNEL_TARGET) gator_driver

$(INSTALLED_KERNEL_TARGET): android_kernel
	ln -sf ../../../../kernel/arch/arm/boot/uImage $(INSTALLED_KERNEL_TARGET)

$(INSTALLED_SYSTEMTARBALL_TARGET): android_kernel_modules out_of_tree_modules

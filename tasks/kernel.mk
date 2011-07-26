android_kernel:
	cd $(TOP)/kernel &&\
	make ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) defconfig $(KERNEL_CONFIG) &&\
	make ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) uImage &&\
	make ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) modules
	mkdir -p $(TOP)/kernel/modules_for_android
	cd $(TOP)/kernel &&\
	make ARCH=arm CROSS_COMPILE=$(shell sh -c "cd $(TOP); cd `dirname $(TARGET_TOOLS_PREFIX)`; pwd")/$(shell basename $(TARGET_TOOLS_PREFIX)) modules_install INSTALL_MOD_PATH=modules_for_android
	mkdir -p $(TARGET_OUT)/lib/modules
	find kernel/modules_for_android -name "*.ko" -exec $(ACP) -fpt {} $(TARGET_OUT)/lib/modules/ \;


$(PRODUCT_OUT)/uImage: android_kernel
	ln -sf ../../../../kernel/arch/arm/boot/uImage $(PRODUCT_OUT)/uImage

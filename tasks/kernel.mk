android_kernel:
	cd $(TOP)/kernel &&\
	make ARCH=arm CROSS_COMPILE=../$(TARGET_TOOLS_PREFIX) defconfig $(KERNEL_CONFIG) &&\
	make ARCH=arm CROSS_COMPILE=../$(TARGET_TOOLS_PREFIX) uImage

$(PRODUCT_OUT)/kernel: android_kernel
	echo HUPP : $(PRODUCT_OUT) : $(TOP) : $(KERNEL_CONFIG) : $(PRODUCT_OUT)/kernel
	ln -sf ../../../../kernel/arch/arm/boot/uImage $(PRODUCT_OUT)/kernel
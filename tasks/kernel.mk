android_kernel:
	cd $(TOP)/kernel &&\
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- defconfig $(KERNEL_CONFIG) &&\
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- uImage

$(PRODUCT_OUT)/kernel: android_kernel
	echo HUPP : $(PRODUCT_OUT) : $(TOP) : $(KERNEL_CONFIG) : $(PRODUCT_OUT)/kernel
	ln -sf ../../../../kernel/arch/arm/boot/uImage $(PRODUCT_OUT)/kernel
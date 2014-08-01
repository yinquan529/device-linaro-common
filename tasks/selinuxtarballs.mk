#
# Trigger build of selinux tar balls for the linaro boards

.PHONY: selinuxtarballs
selinuxtarballs: boottarball systemimage userdataimage
	rm -fr $(PRODUCT_OUT)/selinux
	mkdir -p $(PRODUCT_OUT)/selinux/system
	sudo mount -t ext4 -o loop $(PRODUCT_OUT)/system.img  $(PRODUCT_OUT)/selinux/system
	sudo tar --selinux --numeric-owner -jcvf $(PRODUCT_OUT)/system.tar.bz2 -C $(PRODUCT_OUT)/selinux system
	sudo umount $(PRODUCT_OUT)/selinux/system
	mkdir -p $(PRODUCT_OUT)/selinux/data
	sudo mount -t ext4 -o loop $(PRODUCT_OUT)/userdata.img  $(PRODUCT_OUT)/selinux/data
	sudo tar --selinux --numeric-owner -jcvf $(PRODUCT_OUT)/userdata.tar.bz2 -C $(PRODUCT_OUT)/selinux data
	sudo umount $(PRODUCT_OUT)/selinux/data
	rm -fr $(PRODUCT_OUT)/selinux

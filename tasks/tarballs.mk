#
# Trigger build of tar balls for the linaro boards
#

#######
## root tarball
define build-roottarball-target
    $(hide) echo "Target root fs tarball:" $(INSTALLED_ROOTTARBALL_TARGET)
    $(hide) $(MKTARBALL) $(FS_GET_STATS) \
                 $(PRODUCT_OUT)/root . $(PRIVATE_ROOT_TAR) \
                 $(INSTALLED_ROOTTARBALL_TARGET)
endef

ifndef ROOT_TARBALL_FORMAT
    ROOT_TARBALL_FORMAT := bz2
endif

root_tar := $(PRODUCT_OUT)/root.tar
INSTALLED_ROOTTARBALL_TARGET := $(root_tar).$(ROOT_TARBALL_FORMAT)

$(INSTALLED_ROOTTARBALL_TARGET): PRIVATE_ROOT_TAR := $(root_tar)
$(INSTALLED_ROOTTARBALL_TARGET): $(FS_GET_STATS) $(INTERNAL_RAMDISK_FILES)
	$(build-roottarball-target)

roottarball: $(INSTALLED_ROOTTARBALL_TARGET)
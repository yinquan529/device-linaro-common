# Rules for building bootloaders

BOOTLOADER_TARGETS :=

# Bootloaders have their own separate makefiles and we don't track the
# dependencies these, therefore we need to remake them every time in case
# files need updating. To facilitate this, bootloader rules will depend on
# this phony target...
.PHONY : FORCE_BOOTLOADER_REMAKE

#
# Generate a rule to build U-Boot.
#
# Usage: $(eval $(call MAKE_UBOOT, target-binary, config-name))
#
#   target-binary   Path and name for generated u-boot.bin
#   config-name     Without trailing '_config'
#
#
define MAKE_UBOOT

$(1): $$(ACP) FORCE_BOOTLOADER_REMAKE
	$$(eval _obj := $$(PRODUCT_OUT)/obj/u-boot.$(2))
	@mkdir -p $$(_obj)
	cd $$(TOP)/u-boot && \
	if [ -e $$(UBOOT_TCDIR)/$$(UBOOT_TCPREFIX)ld.bfd ]; then ln -sf $$(UBOOT_TCDIR)/$$(UBOOT_TCPREFIX)ld.bfd $$(UBOOT_TCPREFIX)ld; fi && \
	export PATH=`pwd`:$$(UBOOT_TCDIR):$$(PATH) && \
	$$(MAKE) O=../$$(_obj) CROSS_COMPILE=$$(UBOOT_TCPREFIX) $(2)_config && \
	$$(MAKE) O=../$$(_obj) CROSS_COMPILE=$$(UBOOT_TCPREFIX)
	@mkdir -p $$(dir $$@)
	$$(ACP) -fpt $$(_obj)/u-boot.bin $$@

endef

#
# UBOOT_FLAVOURS contains a list of extra U-Boot binaries to build, each
# entry in the list is in the form <config-name>:<binary-name>
#
UBOOT_FLAVOUR_TARGETS :=
$(foreach _ub,$(UBOOT_FLAVOURS),                      \
    $(eval _config := $(call word-colon,1,$(_ub)))    \
    $(eval _binary := $(call word-colon,2,$(_ub)))    \
    $(eval _target := $(PRODUCT_OUT)/boot/$(_binary)) \
    $(eval $(call MAKE_UBOOT,$(_target),$(_config)))  \
    $(eval UBOOT_FLAVOUR_TARGETS += $(_target))       \
    )

BOOTLOADER_TARGETS += $(UBOOT_FLAVOUR_TARGETS)


ifneq ($(CUSTOM_BOOTLOADER_MAKEFILE),)
include $(TOP)/$(CUSTOM_BOOTLOADER_MAKEFILE)
endif


$(INSTALLED_BOOTTARBALL_TARGET): $(BOOTLOADER_TARGETS)

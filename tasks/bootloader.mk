# Rules for building bootloaders

BOOTLOADER_OUT = $(realpath $(PRODUCT_OUT))/boot
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
	$$(eval UBOOT_FOREST_ROOT:=$$(CURDIR))
	@mkdir -p $$(_obj)
	cd $$(TOP)/$$(UBOOT_SRC) && \
	if [ -e $$(UBOOT_TCDIR)/$$(UBOOT_TCPREFIX)ld.bfd ]; then ln -sf $$(UBOOT_TCDIR)/$$(UBOOT_TCPREFIX)ld.bfd $$(UBOOT_TCPREFIX)ld; fi && \
	export PATH=`pwd`:$$(UBOOT_TCDIR):$$(PATH) && \
	$$(MAKE) O=$$(UBOOT_FOREST_ROOT)/$$(_obj) CROSS_COMPILE=$$(UBOOT_TCPREFIX) $(2)_config && \
	$$(MAKE) O=$$(UBOOT_FOREST_ROOT)/$$(_obj) CROSS_COMPILE=$$(UBOOT_TCPREFIX)
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
    $(eval _target := $(BOOTLOADER_OUT)/$(_binary))   \
    $(eval $(call MAKE_UBOOT,$(_target),$(_config)))  \
    $(eval UBOOT_FLAVOUR_TARGETS += $(_target))       \
    )

BOOTLOADER_TARGETS += $(UBOOT_FLAVOUR_TARGETS)


#
# UEFI
#

ifeq ($(ANDROID_64),true)
UEFI_TOOLS_PREFIX ?= $(realpath $(TOP)/gcc-linaro-aarch64-linux-gnu/bin)/aarch64-linux-android-
endif

ifeq ($(UEFI_TOOLS_PREFIX),)
# UEFI is not an Android application and should be built with the bare
# metal toolchain if it is available...
UEFI_TOOLS_DIR = $(realpath $(dir $(TARGET_TOOLS_PREFIX)))/
UEFI_TOOLS_PREFIX = $(UEFI_TOOLS_DIR)$(shell if [ -e $(UEFI_TOOLS_DIR)arm-eabi-gcc ]; then echo arm-eabi-; else echo $(notdir $(TARGET_TOOLS_PREFIX)); fi)
endif


EDK2_OUT_DIR = $(realpath $(PRODUCT_OUT))/obj/uefi
EDK2_WORKSPACE = $(realpath $(TOP)/uefi/edk2)
EDK2_BASETOOLS := $(EDK2_WORKSPACE)/BaseTools
EDK2_DEB_REL ?= RELEASE
UEFI_ROM_TARGETS :=
UEFI_ROM_INSTALL_TARGET :=


#
# EDK2 setup and tools
#

.PHONY : edk2_setup
edk2_setup :
	rm -f $(EDK2_WORKSPACE)/Conf/tools_def.txt
	cd $(EDK2_WORKSPACE) && \
	export WORKSPACE=$(EDK2_WORKSPACE) && \
	export EDK_TOOLS_PATH=$(EDK2_BASETOOLS) && \
	bash -c "$(EDK2_WORKSPACE)/edksetup.sh $(EDK2_WORKSPACE)"

.PHONY : edk2_setup_clean
edk2_setup_clean :
	cd $(EDK2_WORKSPACE)/Conf && \
	rm -f BuildEnv.sh build_rule.txt FrameworkDatabase.txt target.txt tools_def.txt


.PHONY : edk2_tools
edk2_tools : edk2_setup
	$(MAKE) -j1 -C $(EDK2_BASETOOLS)

.PHONY : edk2_tools_clean
edk2_tools_clean :
	$(MAKE) -j1 -C $(EDK2_BASETOOLS) clean


# Note, the use of "export MAKEFLAGS=" in this rule is done to clear any
# '-j' option which would be inherited by the make processes spawned by
# the 'build' command. Without this, we get an error like:
# "make[1]: *** read jobs pipe: Is a directory. Stop."
#
# We also make the rule for ROMs depend on each other in a chain (using
# EDK2_PREVIOUS_ROM), this forces them to be built one at a time and
# prevents the build error: "IntegrityError: PRIMARY KEY must be unique"

define edk2_build

$(1) : $(2) edk2_tools FORCE_BOOTLOADER_REMAKE | $(EDK2_PREVIOUS_ROM)
	cd $$(EDK2_WORKSPACE) && \
	export WORKSPACE=$$(EDK2_WORKSPACE) && \
	export EDK_TOOLS_PATH=$$(EDK2_BASETOOLS) && \
	export PATH=`pwd`:$$(dir $$(UEFI_TOOLS_PREFIX)):$$(EDK2_BASETOOLS)/BinWrappers/PosixLike:$$(PATH) && \
	export CROSS_COMPILE=$$(notdir $$(UEFI_TOOLS_PREFIX)) && \
	if [ -e $$(UEFI_TOOLS_PREFIX)ld.bfd ]; then \
		echo "Forcing use of GNU linker (as gold doesn't work)"; \
		ln -sf $$(UEFI_TOOLS_PREFIX)ld.bfd $$(notdir $$(UEFI_TOOLS_PREFIX))ld; \
	fi && \
	export MAKEFLAGS= && \
	build -N -t ARMLINUXGCC -b $(EDK2_DEB_REL) -D EDK2_OUT_DIR=$(EDK2_OUT_DIR)/$(3) -D EDK2_USE_ANDROID_CONFIG $(4)

UEFI_ROM_TARGETS += $(1)
EDK2_PREVIOUS_ROM = $(1)

endef

EDK2_PREVIOUS_ROM =


.PHONY : edk2_build_clean
edk2_build_clean :
	rm -rf $(EDK2_WORKSPACE)/Conf/.cache
	rm -rf $(EDK2_OUT_DIR)


define edk2_install

$(1) : $(2) $$(ACP)
	@mkdir -p $$(dir $$@)
	$$(ACP) -fpt $$< $$@

UEFI_ROM_INSTALL_TARGET += $(1)

endef


.PHONY : edk2_clean
edk2_clean : edk2_setup_clean edk2_tools_clean edk2_build_clean


define edk2_rom_name
$(EDK2_OUT_DIR)/$(1)/$(EDK2_DEB_REL)_ARMLINUXGCC/FV/$(2).fd
endef


#
# Generate a rule to build an EDK2 UEFI ROM
#
# Usage: $(eval $(call MAKE_EDK2_ROM, platform-file, build-dir, rom-image, installed-name, arch-type, dependencies))
#
# platform-file   Platform file (.dsc file). Can be abused to add trailing build commands.
# build-dir       Directory, under $(EDK2_OUT_DIR), for build products.
# rom-image       Rom image name (from .fdf file) converted to upper-case.
# installed-name  Name to copy ROM to in boot directory.
# arch-type       [Optional] Target Architecture [ARM, AARCH64 ..]
#                 Default ARCH: ARM
# dependencies    [Optional] List of targets the rule depends on.
#
define MAKE_EDK2_ROM
$(eval $(call edk2_build,$(call edk2_rom_name,$(2),$(3)),$(6),$(2),-a $(or $(5),ARM) -p $(1) -r $(3)))
$(eval $(call edk2_install,$(BOOTLOADER_OUT)/$(4),$(call edk2_rom_name,$(2),$(3))))
endef


#
# Helpers for building RTSM boot-wrappers
#

ifneq ($(BOOTWRAPPER_TOOLS_PREFIX),)
# Used supplied prefix
BOOTWRAPPER_TCDIR = $(realpath $(shell dirname $(BOOTWRAPPER_TOOLS_PREFIX)))
BOOTWRAPPER_TCPREFIX = $(shell basename $(BOOTWRAPPER_TOOLS_PREFIX))
else
BOOTWRAPPER_TCDIR = $(realpath $(shell dirname $(TARGET_TOOLS_PREFIX)))
# The boot-wrapper is not an Android application and should be
# built with the bare metal toolchain if it is available
BOOTWRAPPER_TCPREFIX = $(shell if [ -e $(BOOTWRAPPER_TCDIR)/arm-eabi-gcc ]; then echo arm-eabi-; else basename $(TARGET_TOOLS_PREFIX); fi)
endif

#
# Invoke make with the toolchain setup for cross compilation, example usage:
#
#   cd $$(TOP)/boot-wrapper && $(MAKE_RTSM_BOOTWRAPPER) linux-system-semi.axf
#
# As Linaro's toolchain uses the gold linker and this doesn't work
# correctly for the bootwrapper, this macro checks for the presence of
# BFD LD and forces this into the PATH ahead of everything else, (this is
# based on code in uboot.mk).
#
define MAKE_RTSM_BOOTWRAPPER
	if [ -e $(BOOTWRAPPER_TCDIR)/$(BOOTWRAPPER_TCPREFIX)ld.bfd ]; then ln -sf $(BOOTWRAPPER_TCDIR)/$(BOOTWRAPPER_TCPREFIX)ld.bfd $(BOOTWRAPPER_TCPREFIX)ld; fi && \
	export PATH=`pwd`:$(BOOTWRAPPER_TCDIR):$(PATH) && \
	$(MAKE) CROSS_COMPILE=$(BOOTWRAPPER_TCPREFIX)
endef


#
# Include custom makefiles
#
ifneq ($(CUSTOM_BOOTLOADER_MAKEFILE),)
include $(TOP)/$(CUSTOM_BOOTLOADER_MAKEFILE)
endif


BOOTLOADER_TARGETS += $(UEFI_ROM_INSTALL_TARGET)

.PHONY : uefi_roms
uefi_roms : $(UEFI_ROM_TARGETS)


$(INSTALLED_BOOTTARBALL_TARGET): $(BOOTLOADER_TARGETS)

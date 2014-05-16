# similar to common.mk, this file is only for AOSP master based armv8 related build now
# in the future will be replaced by common.mk or replace the common.mk

COMMON_EXTRA_TESTS_DIR := device/linaro/common/extra-and-tests/

# integrate the ZeroXBenchmark application into the image
# http://android.git.linaro.org/git/platform/packages/apps/0xbench
-include $(COMMON_EXTRA_TESTS_DIR)/ZeroXBenchmark.mk

# integrate the tests of bionic libc into the image
# repository: http://android.git.linaro.org/git/platform/system/extras
# path: tests/bionic/libc/
-include $(COMMON_EXTRA_TESTS_DIR)/bionic-libc-tests.mk

# integrate the tests of linaro-android-kernel
# repository: ssh://linaro-private.git.linaro.org/srv/linaro-private.git.linaro.org/android/linaro-android-kernel-test
-include external/linaro-android-kernel-test/product.mk

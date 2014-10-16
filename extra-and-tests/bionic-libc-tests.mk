#############################################################################
# Copyright (c) 2013 Linaro
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     Linaro <linaro-android@lists.linaro.org>
#############################################################################

BIONIC_LIBC_NATIVE_TEST := \
    libdlclosetest1 \
    libdlclosetest2 \
    libtest_relocs \
    libtest_static_init \
    test_aligned \
    test_dlclose_destruction \
    test_dlopen_null \
    test_executable_destructor \
    test_getaddrinfo \
    test_getgrouplist \
    test_gethostbyname \
    test_gethostname \
    test_mutex \
    test_netinet_icmp \
    test_pthread_cond \
    test_pthread_mutex \
    test_pthread_once \
    test_pthread_rwlock \
    test_relocs \
    test_setjmp \
    test_seteuid \
    test_static_cpp_mutex \
    test_static_executable_destructor \
    test_static_init \
    test_sysconf \
    test_udp

PRODUCT_COPY_FILES += $(COMMON_EXTRA_TESTS_DIR)/run-bionic-tests.sh:system/bin/run-bionic-tests.sh

BIONIC_TESTS := true

PRODUCT_PACKAGES += \
    $(BIONIC_LIBC_NATIVE_TEST) \

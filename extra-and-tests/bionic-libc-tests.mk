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

# pick up tests to build the system image
#BIONIC_LIBC_NATIVE_TEST_NOT_EXIST := \
#    bench_stdio \
#    test_drand48 \
#    test_pthread_getcpuclockid \
#    test_strftime_2039 \
#    test_strptime \
#    test_tm_zone \
#    test_libgen \
#    bench_locks \
#    test_system \
#    test_timer_create \
#    test_timer_create2 \
#    test_timer_create3 \
#    test_clone \
#    bench_pthread_shared \
#    bench_pthread_static \
#    test_atomics \

#BIONIC_LIBC_NATIVE_TEST_NOT_USED := \
#    bench_pthread \
#    test_thread_max

BIONIC_LIBC_NATIVE_TEST := \
    libdlclosetest1 \
    libdlclosetest2 \
    libtest_relocs \
    libtest_static_init \
    test_aligned \
    test_arc4random \
    test_clock \
    test_cpu_set \
    test_dlclose_destruction \
    test_dlopen_null \
    test_executable_destructor \
    test_getaddrinfo \
    test_getgrouplist \
    test_gethostbyname \
    test_gethostname \
    test_mutex \
    test_netinet_icmp \
    test_pthread_cleanup_push \
    test_pthread_cond \
    test_pthread_create \
    test_pthread_join \
    test_pthread_mutex \
    test_pthread_once \
    test_pthread_rwlock \
    test_relocs \
    test_semaphore \
    test_sem_post \
    test_setjmp \
    test_seteuid \
    test_static_cpp_mutex \
    test_static_executable_destructor \
    test_static_init \
    test_sysconf \
    test_udp \
    test_vfprintf_leak

PRODUCT_COPY_FILES += $(COMMON_EXTRA_TESTS_DIR)/run-bionic-tests.sh:system/bin/run-bionic-tests.sh

PRODUCT_PACKAGES += \
    $(BIONIC_LIBC_NATIVE_TEST) \

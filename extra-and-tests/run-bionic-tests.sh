#############################################################################
# Copyright (c) 2013 Linaro
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     Linaro <linaro-android@lists.linaro.org>
#
# Usage:
#     This test script is used to run all stock bionic/libc tests in one go
#     and capture results in LAVA.
#     Test sources are available at "system/extras/tests/bionic/libc"
#############################################################################

TESTS="test_arc4random test_clock test_cpu_set test_dlclose_destruction test_dlopen_null test_executable_destructor test_getaddrinfo test_getgrouplist test_gethostbyname test_gethostname test_mutex test_netinet_icmp test_pthread_cleanup_push test_pthread_cond test_pthread_create test_pthread_join test_pthread_mutex test_pthread_once test_pthread_rwlock test_relocs test_semaphore test_sem_post test_setjmp test_seteuid test_static_cpp_mutex test_static_executable_destructor test_static_init test_sysconf test_udp test_vfprintf_leak"

# Rogue tests
#TESTS+= "test_cond test_thread_max test_timer_create test_timer_create2 bench_stdio test_drand48 test_pthread_getcpuclockid test_strftime_2039 test_strptime test_tm_zone test_libgen bench_locks test_system test_timer_create3 test_clone bench_pthread_shared bench_pthread_static bench_pthread test_atomics "

for TEST in $TESTS; do
	$TEST
	EXIT_STATUS=$?
	if [ $EXIT_STATUS -ne 0 ]; then
		echo "$TEST : FAIL"
	else
		echo "$TEST : PASS"
	fi
done

# test_system date
# EXIT_STATUS=$?
#if [ $EXIT_STATUS -ne 0 ]; then
#	echo "$TEST : FAIL"
#else
#	echo "$TEST : PASS"
#fi

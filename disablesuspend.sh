#!/system/bin/sh
#
# Author: Linaro Validation Team <linaro-dev@lists.linaro.org>
#
# These files are Copyright (C) 2012 Linaro Limited and they
# are licensed under the Apache License, Version 2.0.
# You may obtain a copy of this license at
# http://www.apache.org/licenses/LICENSE-2.0

    stay_awake="delete from system where name='stay_on_while_plugged_in'; insert into system (name, value) values ('stay_on_while_plugged_in','3');"
    screen_sleep="delete from system where name='screen_off_timeout'; insert into system (name, value) values ('screen_off_timeout','-1');"
    lockscreen="delete from secure where name='lockscreen.disabled'; insert into secure (name, value) values ('lockscreen.disabled','1');"
    sqlite3 /data/data/com.android.providers.settings/databases/settings.db "${stay_awake}" ## set stay awake
    sqlite3 /data/data/com.android.providers.settings/databases/settings.db "${screen_sleep}" # set sleep to none
    sqlite3 /data/data/com.android.providers.settings/databases/settings.db "${lockscreen}" ##set lock screen to none
    input keyevent 82  ##unlock the home screen
    service call power 1 i32 26 ##acquireWakeLock FULL_WAKE_LOCK

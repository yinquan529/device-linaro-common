#!/system/bin/sh
# Copyright (C) 2012 Linaro Limited

# Author: Linaro Validation Team <linaro-dev@lists.linaro.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

    stay_awake="delete from system where name='stay_on_while_plugged_in'; insert into system (name, value) values ('stay_on_while_plugged_in','3');"
    screen_sleep="delete from system where name='screen_off_timeout'; insert into system (name, value) values ('screen_off_timeout','-1');"
    lockscreen="delete from secure where name='lockscreen.disabled'; insert into secure (name, value) values ('lockscreen.disabled','1');"
    sqlite3 /data/data/com.android.providers.settings/databases/settings.db "${stay_awake}" ## set stay awake
    sqlite3 /data/data/com.android.providers.settings/databases/settings.db "${screen_sleep}" # set sleep to none
    sqlite3 /data/data/com.android.providers.settings/databases/settings.db "${lockscreen}" ##set lock screen to none
    input keyevent 82  ##unlock the home screen
    service call power 1 i32 26 ##acquireWakeLock FULL_WAKE_LOCK

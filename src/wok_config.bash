
#
# Copyright © 2013 Max Ruman
#
# This file is part of Wok.
#
# Wok is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# Wok is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
# License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with Wok. If not, see <http://www.gnu.org/licenses/>.
#

wok_config_get()
{
	local section="$1"
	local key="$2"

	if ! ini_get "$WOK_CONFIG_FILE" "$section" "$key" 2>/dev/null; then
		#FIXME: This command may NOT make the whole stuff exit!? Or sys err always exit?
		wok_exit $EXIT_ERR_SYS
	fi
}


#
# Copyright © 2013-2015 Max Ruman <rmx@guanako.be>
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
		wok_error "Could not load configuration value '${section}:${key}' from file '${WOK_CONFIG_FILE}'"
		wok_exit $EXIT_ERR_SYS
	fi
}

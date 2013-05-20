
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

#
# Get a string from the user. The result will be stored into $<out_var>.
# You must provide a regex pattern.
#
# Usage: ui_getString <out_var> <pattern> <message>
#
ui_getString()
{
	local __var_ref="$1"
	local __pattern="$2"
	local __message="$3"
	local __value

	while true; do
		read -ep "${__message}: " __value

		if ! [[ $__value =~ $__pattern ]]; then
			echo -e "Invalid value (pattern: \033[0;33m${__pattern}\033[0m), please try again..."
			continue
		fi

		break
	done

	printf -v "$__var_ref" %s "$__value"
}

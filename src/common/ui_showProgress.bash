
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
# Show a simple progress dialog with success/fail catch.
#
# Usage: ui_Progress <message> <command> [argument_1..n]
#
ui_showProgress()
{
	echo -n "${1}..."
	shift
	if "$@" >/dev/null 2>/dev/null; then
		echo "done."
		return 0
	else
		echo -e "\033[0;31mfailed!\033[0m"
		return 1
	fi
}

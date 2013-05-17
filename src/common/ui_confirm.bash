
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
# Ask an interactive user to confirm an action.
#
# Usage: ui_confirm <action> (&& PERFORM_ACTION || CANCEL)
#
# @return bool Confirmation
#
ui_confirm()
{
	local action="$1"
	local user_resp=""

	[[ -z $action ]] && action="Proceed?"

	while true; do
		read -ep "${action} [y/n]: " user_resp
		if [[ ${user_resp:0:1} == [yY] ]]; then
			return 0
		elif [[ ${user_resp:0:1} == [nN] ]]; then
			return 1
		fi
	done
}

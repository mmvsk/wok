
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
# Ask an interactive user to choose between N given choices. The result
# will be stored into $<out_var>.
#
# Usage: ui_getChoice [-m <message>] <out_var> <choice_1> [... <choice_N>]
#
ui_getChoice()
{
	local message
	local out_var
	local user_choice
	local choices=()
	local i=1

	if [[ $1 == "-m" ]]; then
		message="$2"
		shift 2
	fi

	[[ $# -lt 2 ]] && return 1

	out_var="$1"
	shift

	if [[ -n $message ]]; then
		echo "${message}:"
	fi
	echo
	for choice in "$@"; do
		echo "${i}. ${choice}"
		((i++))
	done
	echo
	while true; do
		read -ep "Your choice: " user_choice
		if [[ $user_choice =~ ^[0-9+]$ ]] \
		&& [[ $user_choice -ge 1 ]] \
		&& [[ $user_choice -lt $i ]]; then
			break
		fi
	done
	printf -v "$out_var" %d $user_choice
}


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
# Ask the user to choose a password. The passwd will be asked twice and
# won't be printed on the screen. The result will be stored into
# $<out_var>.
#
# You can also enforce the password syntax using a regular expression.
#
# Usage: user_getPasswd [-m <message>] <out_var> <regex_pattern>
#
user_getPasswd()
{
	local message="Password"
	local out_var
	local passwd
	local passwd_confirm

	if [[ $1 == "-m" ]]; then
		message="$2"
		shift 2
	fi

	[[ $# -lt 1 ]] && return 1

	out_var="$1"
	pattern="$2"

	while true; do
		read -s -ep "${message}: " passwd; echo
		if [[ -n $pattern ]] && ! [[ $passwd =~ $pattern ]]; then
			echo -e "Invalid password (pattern: \033[0;33m${pattern}\033[0m), please try again..."
			continue
		fi
		read -s -ep "${message} (again): " passwd_confirm; echo
		if [[ $passwd == $passwd_confirm ]]; then
			break
		else
			echo "Password mismatch, please try again..."
			continue
		fi
	done

	printf -v "$out_var" %s "$passwd"
}

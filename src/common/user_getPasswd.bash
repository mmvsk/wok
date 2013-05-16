
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
	local __var_ref="$1"
	local __pattern="$2"
	local __message="$3"
	local __passwd
	local __passwd_confirm

	if [[ -z $__message ]]; then
		__message="Password"
	fi

	while true; do
		read -s -ep "${__message}: " __passwd; echo
		if [[ -n $__pattern ]] && ! [[ $__passwd =~ $__pattern ]]; then
			echo -e "Invalid password (pattern: \033[0;33m${__pattern}\033[0m), please try again..."
			continue
		fi
		read -s -ep "${__message} (again): " __passwd_confirm; echo
		if [[ $__passwd == $__passwd_confirm ]]; then
			break
		else
			echo "Password mismatch, please try again..."
			continue
		fi
	done

	printf -v "$__var_ref" %s "$__passwd"
}

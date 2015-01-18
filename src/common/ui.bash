
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

#
# Ask the user to choose a password. The passwd will be asked twice and
# won't be printed on the screen. The result will be stored into
# $<out_var>.
#
# You can also enforce the password syntax using a regular expression.
#
# Usage: ui_getPasswd <out_var> <regex_pattern> [<message>]
#
ui_getPasswd()
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

#
# Show a simple progress dialog with success/fail catch.
#
# Usage: ui_Progress <message> <command> [argument_1..n]
#
ui_showProgress()
{
	local message="$1"
	shift
	local cmd=("$@")
	local err="$(mktemp)"

	echo -n "${message}..."
	shift
	if ("${cmd[@]}") >/dev/null 2>"$err"; then
		echo "done."
		rm "$err"
		return 0
	else
		echo -e "\033[0;31mfailed!\033[0m"
		cat "$err"
		rm "$err"
		return 1
	fi
}

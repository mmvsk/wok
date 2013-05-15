
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
# Reverse the order of an list
#
# Usage: list_reverse <list_var_name>
#
#   arr=("hello world" "bonjour le monde")
#   list_reverse arr
#   # ("bonjour le monde" "hello world")
#   
# Variables you use must not start with '__'.
#
list_reverse()
{
	local __list_ref="$1"
	local __list_values=()
	eval "__list_values=(\"\${${1}[@]}\")"
	local __i_val=()
	local __eval_values=""

	for __i_val in "${__list_values[@]}"; do
		__eval_values="$(printf %q "${__i_val}") ${__eval_values}"
	done

	eval "${__list_ref}=(${__eval_values})"
}

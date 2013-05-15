
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
# Adds a value to an list
#
# Usage: list_add <list_var_name> <value>
#
#   arr=("hello world" "bonjour le monde")
#   list_add arr "buenos dias"
#   
# Variables you use must not start with '__'.
#
list_add()
{
	local __list_ref="$1"
	local __list_values=()
	eval "__list_values=(\"\${${1}[@]}\")"
	local __value="$2"
	local __i_val=()
	local __eval_values=""

	for __i_val in "${__list_values[@]}"; do
		if [[ $__value == $__i_val ]]; then
			return 1
		fi
	done

	for __i_val in "${__list_values[@]}" "$__value"; do
		__eval_values="${__eval_values} $(printf %q "${__i_val}")"
	done

	eval "${__list_ref}=(${__eval_values})"
}

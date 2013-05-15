
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
	local __list_add__list_name="$1"
	local __list_add__list_values=()
	eval "__list_add__list_values=(\"\${${1}[@]}\")"
	local __list_add__value="$2"
	local __list_add__i_val=()
	local __list_add__eval_values=""

	for __list_add__i_val in "${__list_add__list_values[@]}"; do
		if [[ $__list_add__value == $__list_add__i_val ]]; then
			return 1
		fi
	done

	for __list_add__i_val in "${__list_add__list_values[@]}" "$__list_add__value"; do
		__list_add__eval_values="${__list_add__eval_values} $(printf %q "${__list_add__i_val}")"
	done

	eval "${__list_add__list_name}=(${__list_add__eval_values})"
}

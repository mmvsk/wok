
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
# Check if an array contains a value
#
# Usage: array_has <array_name> <element>
#
#   arr=("hello world" "bonjour le monde")
#   if array_has arr "bonjour le monde"; then
#     #...
#   fi
#
# Given array name mustn't begin with '' (in fact, it never
# should begin with '__').
#
array_has()
{
	local array_ref="${1}[@]"
	local array=("${!array_ref}")
	local value="$2"
	local array_val

	for array_val in "${array[@]}"; do
		if [[ $value == $array_val ]]; then
			return 0
		fi
	done

	return 1
}

#
# Add a value to an array
#
# Usage: array_add <array_var_name> <value>
#
#   arr=("hello world" "bonjour le monde")
#   array_add arr "buenos dias"
#   
# Variables you use must not start with '__'.
#
array_add()
{
	local __array_ref="$1"
	local __array_values=()
	eval "__array_values=(\"\${${1}[@]}\")"
	local __value="$2"
	local __i_val=()
	local __eval_values=""

	if array_has __array_values "$__value"; then
		return 1
	fi

	for __i_val in "${__array_values[@]}" "$__value"; do
		__eval_values="${__eval_values} $(printf %q "${__i_val}")"
	done

	eval "${__array_ref}=(${__eval_values})"
}

#
# Reverse the order of an array
#
# Usage: array_reverse <array_var_name>
#
#   arr=("hello world" "bonjour le monde")
#   array_reverse arr
#   # ("bonjour le monde" "hello world")
#   
# Variables you use must not start with '__'.
#
array_reverse()
{
	local __array_ref="$1"
	local __array_values=()
	eval "__array_values=(\"\${${1}[@]}\")"
	local __i_val=()
	local __eval_values=""

	for __i_val in "${__array_values[@]}"; do
		__eval_values="$(printf %q "${__i_val}") ${__eval_values}"
	done

	eval "${__array_ref}=(${__eval_values})"
}

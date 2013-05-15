
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
# Check if an list contains a value
#
# Usage: list_has <list_name> <element>
#
#   arr=("hello world" "bonjour le monde")
#   if list_has arr "bonjour le monde"; then
#     #...
#   fi
#
# Given list name mustn't begin with '__list_has' (in fact, it never
# should begin with '__').
#
list_has()
{
	local __list_has__list_name="${1}[@]"
	local list=("${!__list_has__list_name}")
	local value="$2"
	local list_val

	for list_val in "${list[@]}"; do
		if [[ $value == $list_val ]]; then
			return 0
		fi
	done

	return 1
}

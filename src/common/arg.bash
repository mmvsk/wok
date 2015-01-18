
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
# Retrieve and print the “value” part of a command-line argument
#
# Usage: arg_parseValue <argument>
#
arg_parseValue()
{
	local arg="$1"
	local value

	# Short: -u"username"
	if [[ $arg =~ ^-[[:alnum:]_]. ]]; then
		echo "${arg:2}"
		return 0

	# Long: --username="username"
	elif [[ $arg =~ ^--[[:alnum:]_][[:alnum:]_\-]+= ]]; then
		echo "${arg#*=}"
		return 0

	fi
	return 1
}

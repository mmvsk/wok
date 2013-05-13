
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

wok_add()
{
	local arg
	local arg_value

	local opt_domain=""
	local opt_interactive=false
	local opt_cascade=false
	local opt_passwd=
	local opt_passwd_generate=true

	for arg in "$@"; do
		arg_value="$(arg_parseValue "$arg")"


	done


	wok_repo_has "$domain"
}

wok_remove()
{
	echo REMOVE $*
}

wok_list()
{
	echo LIST $*
}

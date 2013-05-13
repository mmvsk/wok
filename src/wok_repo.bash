
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

# TODO USE INI_GET, INI_SET
#
# /index/
#   <module>/
#     domain.list
#     uid.list
#
# /lessources.be.ini
# /lesmachins.be.ini
#


wok_repo_has()
{
	local domain="$1"
}

wok_repo_index_has()
{
	local module="$1"
	local section="$2"
	local token="$3"
}



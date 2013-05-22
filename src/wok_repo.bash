
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

WOK_REPO_DOMAIN_INDEX="${WOK_REPO_PATH}/domain.index"

#
# Usage: wok_repo_has <domain>
#
# @param string $domain Domain name
# @return bool Existence
#
wok_repo_has()
{
	local domain="$1"

	index_has "$WOK_REPO_DOMAIN_INDEX" "$domain"
}

#
# Usage: wok_repo_add <domain>
#
# @param string $domain Domain name
# @return bool Success
#
wok_repo_add()
{
	local domain="$1"

	index_add "$WOK_REPO_DOMAIN_INDEX" "$domain"
}

#
# Usage: wok_repo_remove <domain>
#
# @param string $domain Domain name
# @return bool Success
#
wok_repo_remove()
{
	local domain="$1"

	index_remove "$WOK_REPO_DOMAIN_INDEX" "$domain"
}

#
# Usage: wok_repo_list
#
# @print Domain list
#
wok_repo_list()
{
	cat "$WOK_REPO_DOMAIN_INDEX"
}

#
# Usage: wok_repo_module_has <module> <domain>
#
wok_repo_module_has()
{
	# index_has <index_path> <token>
	# index_add <index_path> <token>
	# index_remove <index_path> <token>
	#
	# $repo/modules/<module>/<domain>.ini
	# $repo/modules/<module>/index/<index>.index
	#
	# $WOK_REPO_PATH
}

#
# Usage: wok_repo_module_add <module> <domain>
#
wok_repo_module_add()
{
	# index_has <index_path> <token>
	# index_add <index_path> <token>
	# index_remove <index_path> <token>
	#
	# $repo/modules/<module>/<domain>.ini
	# $repo/modules/<module>/index/<index>.index
	#
	# $WOK_REPO_PATH
}

#
# Usage: wok_repo_module_remove <module> <domain>
#
wok_repo_module_remove()
{
	# index_has <index_path> <token>
	# index_add <index_path> <token>
	# index_remove <index_path> <token>
	#
	# $repo/modules/<module>/<domain>.ini
	# $repo/modules/<module>/index/<index>.index
	#
	# $WOK_REPO_PATH
}

#
# Usage: wok_repo_module_list <module> <domain>
#
wok_repo_module_list()
{
	# index_has <index_path> <token>
	# index_add <index_path> <token>
	# index_remove <index_path> <token>
	#
	# $repo/modules/<module>/<domain>.ini
	# $repo/modules/<module>/index/<index>.index
	#
	# $WOK_REPO_PATH
}

#
# Usage: wok_repo_module_data_set <module> <domain> <key> <value>
#
wok_repo_module_data_set()
{
	# json_set <jsonFile_path> <key> <value>
	# json_get <jsonFile_path> <key>
	#
	# $repo/modules/<module>/<domain>.ini
	# $repo/modules/<module>/index/<index>.index
	#
	# $WOK_REPO_PATH
}

#
# Usage: wok_repo_module_get <module> <domain> <key>
#
wok_repo_module_data_get()
{
	# json_set <jsonFile_path> <key> <value>
	# json_get <jsonFile_path> <key>
	#
	# $repo/modules/<module>/<domain>.ini
	# $repo/modules/<module>/index/<index>.index
	#
	# $WOK_REPO_PATH
}

#
# Usage: wok_repo_module_index_has <module> <index> <token>
#
wok_repo_module_index_has()
{
	# index_has <index_path> <token>
	# index_add <index_path> <token>
	# index_remove <index_path> <token>
	#
	# $repo/modules/<module>/<domain>.ini
	# $repo/modules/<module>/index/<index>.index
	#
	# $WOK_REPO_PATH
}

#
# Usage: wok_repo_module_index_add <module> <index> <token>
#
wok_repo_module_index_add()
{
	# index_has <index_path> <token>
	# index_add <index_path> <token>
	# index_remove <index_path> <token>
	#
	# $repo/modules/<module>/<domain>.ini
	# $repo/modules/<module>/index/<index>.index
	#
	# $WOK_REPO_PATH
}

#
# Usage: wok_repo_module_index_remove <module> <index> <token>
#
wok_repo_module_index_remove()
{
	# index_has <index_path> <token>
	# index_add <index_path> <token>
	# index_remove <index_path> <token>
	#
	# $repo/modules/<module>/<domain>.ini
	# $repo/modules/<module>/index/<index>.index
	#
	# $WOK_REPO_PATH
}

#
# Usage: wok_repo_module_index_list <module> <index>
#
wok_repo_module_index_list()
{
	# index_has <index_path> <token>
	# index_add <index_path> <token>
	# index_remove <index_path> <token>
	#
	# $repo/modules/<module>/<domain>.ini
	# $repo/modules/<module>/index/<index>.index
	#
	# $WOK_REPO_PATH
}

#
# Usage: wok_repo_module_index_getPath <module> <index>
#
wok_repo_module_index_getPath()
{
	# index_has <index_path> <token>
	# index_add <index_path> <token>
	# index_remove <index_path> <token>
	#
	# $repo/modules/<module>/<domain>.ini
	# $repo/modules/<module>/index/<index>.index
	#
	# $WOK_REPO_PATH
}

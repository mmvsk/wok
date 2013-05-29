
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
# @param  string $domain Domain name
# @return bool           Existence
#
wok_repo_has()
{
	local domain="$1"

	index_has "$WOK_REPO_DOMAIN_INDEX" "$domain"
}

#
# Usage: wok_repo_add <domain>
#
# @param  string $domain Domain name
# @return bool           Success
#
wok_repo_add()
{
	local domain="$1"

	index_add "$WOK_REPO_DOMAIN_INDEX" "$domain"
}

#
# Usage: wok_repo_remove <domain>
#
# @param  string $domain Domain name
# @return bool           Success
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
# @param  string $module Module name
# @param  string $domain Domain name
# @return bool           Existence
#
wok_repo_module_has()
{
	local module="$1"
	local domain="$2"

	index_has "${WOK_REPO_PATH}/modules/${module}/domain.index" "$domain"
}

#
# Usage: wok_repo_module_add <module> <domain>
#
# @param  string $module Module name
# @param  string $domain Domain name
# @return bool           Success
#
wok_repo_module_add()
{
	local module="$1"
	local domain="$2"

	index_add "${WOK_REPO_PATH}/modules/${module}/domain.index" "$domain"
}

#
# Usage: wok_repo_module_remove <module> <domain>
#
# @param  string $module Module name
# @param  string $domain Domain name
# @return bool           Success
#
wok_repo_module_remove()
{
	local module="$1"
	local domain="$2"

	index_remove "${WOK_REPO_PATH}/modules/${module}/domain.index" "$domain"
}

#
# Usage: wok_repo_module_list <module>
#
# @param string $module Module name
# @print                Domain list
#
wok_repo_module_list()
{
	local module="$1"

	cat "${WOK_REPO_PATH}/modules/${module}/domain.index"
}

#
# Usage: wok_repo_module_data_set <module> <domain> <key> [<value>]
#
# @param string      $module Module name
# @param string      $domain Domain name
# @param string      $key    Data key
# @param string|null $value  If defined, the value to set. If missing,
#                            it will unset the key
# @return bool               Success
#
wok_repo_module_data_set()
{
	local module="$1"
	local domain="$2"
	local key="$3"
	local value="$4"

	if [[ $# -ge 4 ]]; then
		# Action: set key value
		json_set "${WOK_REPO_PATH}/modules/${module}/data/${domain}.json" "$key" "$value"
	else
		# Action: unset key
		json_set "${WOK_REPO_PATH}/modules/${module}/data/${domain}.json" "$key"
	fi
}

#
# Usage: wok_repo_module_data_get <module> <domain> <key>
#
# @param  string $module Module name
# @param  string $domain Domain name
# @param  string $key    Data key
# @print  string         The value
# @return bool           Success
#
wok_repo_module_data_get()
{
	local module="$1"
	local domain="$2"
	local key="$3"

	json_get "${WOK_REPO_PATH}/modules/${module}/data/${domain}.json" "$key"
}

#
# Completely removes the JSON file.
#
# Usage: wok_repo_module_data_get <module> <domain>
#
# @param  string $module Module name
# @param  string $domain Domain name
# @return bool           Success
#
wok_repo_module_data_remove()
{
	local module="$1"
	local domain="$2"

	local file="${WOK_REPO_PATH}/modules/${module}/data/${domain}.json"

	if [[ ! -f $file ]]; then
		return 1
	fi

	rm "$file"
}

#
# Usage: wok_repo_module_index_has <module> <index> <token>
#
# @param  string $module Module name
# @param  string $index  Index name (e.g. slug, uid, ...)
# @return bool           Existence
#
wok_repo_module_index_has()
{
	local module="$1"
	local index="$2"
	local token="$3"

	index_has "${WOK_REPO_PATH}/modules/${module}/index/${index}.index" "$token"
}

#
# Usage: wok_repo_module_index_add <module> <index> <token>
#
# @param  string $module Module name
# @param  string $index  Index name (e.g. slug, uid, ...)
# @return bool           Success
#
wok_repo_module_index_add()
{
	local module="$1"
	local index="$2"
	local token="$3"

	index_add "${WOK_REPO_PATH}/modules/${module}/index/${index}.index" "$token"
}

#
# Usage: wok_repo_module_index_remove <module> <index> <token>
#
# @param  string $module Module name
# @param  string $index  Index name (e.g. slug, uid, ...)
# @return bool           Success
#
wok_repo_module_index_remove()
{
	local module="$1"
	local index="$2"
	local token="$3"

	index_remove "${WOK_REPO_PATH}/modules/${module}/index/${index}.index" "$token"
}

#
# Usage: wok_repo_module_index_list <module> <index>
#
# @param string $module Module name
# @param string $index  Index name (e.g. slug, uid, ...)
# @print                Token list
#
wok_repo_module_index_list()
{
	local module="$1"
	local index="$2"

	cat "${WOK_REPO_PATH}/modules/${module}/index/${index}.index"
}

#
# Usage: wok_repo_module_index_getPath <module> <index>
#
# @param  string $module Module name
# @param  string $index  Index name (e.g. slug, uid, ...)
# @print                 Index file path
#
wok_repo_module_index_getPath()
{
	local module="$1"
	local index="$2"
	local path

	path="${WOK_REPO_PATH}/modules/${module}/index/${index}.index"
	if [[ ! -f $path ]]; then
		touch "$path"
	fi
	echo "$path"
}

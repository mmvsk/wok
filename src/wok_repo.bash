
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
# Uses
# ----------------------------
# 
# ini_set <file> <section> <key> <value>
# ini_get <file> <section> <key>
#
# Directory structure
# ------------------------------------------
#
# $repo/domain.index
# $repo/modules/<module>/<domain>.ini
# $repo/modules/<module>/index/<index>.index
#
# Functions
# -----------------------------------------------------------
#
# Usage: wok_repo_has <domain>
# Usage: wok_repo_add <domain>
# Usage: wok_repo_remove <domain>
# Usage: wok_repo_list <domain>
#
# Usage: wok_repo_module_has <module> <domain>
# Usage: wok_repo_module_add <module> <domain>
# Usage: wok_repo_module_remove <module> <domain>
# Usage: wok_repo_module_list <module> <domain>
#
# Usage: wok_repo_module_set <module> <domain> <key> <value>
# Usage: wok_repo_module_get <module> <domain> <key>
#
# Usage: wok_repo_module_index_has <module> <index> <name>
# Usage: wok_repo_module_index_add <module> <index> <name>
# Usage: wok_repo_module_index_remove <module> <index> <name>
# Usage: wok_repo_module_index_list <module> <index>
# Usage: wok_repo_module_index_getPath <module> <index>
#
# WOK_REPO_PATH
#

wok_repo_has()
{
	local domain="$1"

	return 1
}

wok_repo_add()
{
	local domain="$1"
}

wok_repo_cust_has()
{
	local module="$1"
	local section="$2"
	local token="$3"
}

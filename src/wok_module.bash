
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

wok_module_has()
{
	local module="$1"
	local availModule

	for availModule in "${wok_module_list[@]}"; do
		[[ $module == $availModule ]] && return 0
	done
	return 1
}

wok_module_handle()
{
	local module="$1"
	shift
	local handler="wok_${module}_handle"
	local param="$@"

	if ! wok_module_has "$module"; then
		wok_exit $EXIT_USER_ERROR "Invalid module: ${module}"
	fi

	if ! "$handler" "${param[@]}"; then
		wok_exit $EXIT_SYSTEM_ERROR "Module error"
	fi
}

wok_module_cascade()
{
	local action="$1"
	shift
	local options=("$@")
	local modules=($(wok_config_get wok modules))

	for module in ${modules[@]}; do
		if ! wok_module_has "$module"; then
			wok_exit $EXIT_USER_ERROR "Invalid module: ${module}"
		fi

		wok_module_handle "$module" "$action" "${options[@]}"
	done
}


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

wok_module_describe()
{
	local module="$1"
	local handler="wok_${module}_describe"
	local description

	if ! wok_module_has "$module"; then
		wok_perror "Unavailable module: ${module}"
		wok_exit $EXIT_ERROR_SYSTEM
	fi

	if ! description="$("$handler")"; then
		wok_perror "Module error"
		wok_exit $EXIT_ERROR_SYSTEM
	fi

	echo "$description"
}

#
# Return a simple word list separated by a space
#
wok_module_pdeps()
{
	local module="$1"
	local handler="wok_${module}_pdeps"
	local deps

	if ! wok_module_has "$module"; then
		wok_perror "Unavailable module: ${module}"
		wok_exit $EXIT_ERROR_SYSTEM
	fi

	if ! deps="$("$handler")"; then
		wok_perror "Module error"
		wok_exit $EXIT_ERROR_SYSTEM
	fi

	echo "$deps"
}

wok_module_handle()
{
	local module="$1"
	shift
	local handler="wok_${module}_handle"
	local param="$@"

	if ! wok_module_has "$module"; then
		wok_perror "Unavailable module: ${module}"
		wok_exit $EXIT_ERROR_SYSTEM
	fi

	if ! "$handler" "${param[@]}"; then
		wok_perror "Module error"
		wok_exit $EXIT_ERROR_SYSTEM
	fi
}

wok_module_getDefaults()
{
	wok_config_get wok modules
}

wok_module_orderList()
{
	local __list_ref="$1"
	local __modules=()
	eval "__modules=(\"\${${1}[@]}\")"
	local __module
	local __dep
	local __ordered=()

	for __module in "${__modules[@]}"; do
		for __dep in $(wok_module_pdeps "$__module"); do
			if ! list_has __ordered "$__dep"; then
				continue 2
				#TODO if during a full loop nothing happenned, stop and exit sys error
			fi
		done
		list_add __ordered "$__module"
	done
}

wok_module_cascade()
{
	local modules="$1" #TODO get real list...
	local action="$2"
	shift
	local options=("$@")
	local modules=($(wok_config_get wok modules))

	for module in ${modules[@]}; do
		if ! wok_module_has "$module"; then
			wok_exit $EXIT_ERROR_USER "Invalid module: ${module}"
		fi

		wok_module_handle "$module" "$action" "${options[@]}"
	done
}

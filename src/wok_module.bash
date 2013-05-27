
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

	for availModule in "${WOK_MODULE_LIST[@]}"; do
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
		wok_exit $EXIT_ERR_SYS
	fi

	if ! description="$("$handler")"; then
		wok_perror "Module error"
		wok_exit $EXIT_ERR_SYS
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
		wok_exit $EXIT_ERR_SYS
	fi

	if ! deps="$("$handler")"; then
		wok_perror "Module error"
		wok_exit $EXIT_ERR_SYS
	fi

	echo "$deps"
}

#
# Return a simple word list separated by a space
#
wok_module_pname()
{
	local module="$1"
	local handler="wok_${module}_pname"
	local name

	if ! wok_module_has "$module"; then
		wok_perror "Unavailable module: ${module}"
		wok_exit $EXIT_ERR_SYS
	fi

	if ! name="$("$handler")"; then
		wok_perror "Module error"
		wok_exit $EXIT_ERR_SYS
	fi

	echo "$name"
}

wok_module_handle()
{
	local module="$1"
	shift
	local handler="wok_${module}_handle"
	local param=("$@")

	if ! wok_module_has "$module"; then
		wok_perror "Unavailable module: ${module}"
		wok_exit $EXIT_ERR_SYS
	fi

	if ! "$handler" "${param[@]}"; then
		wok_perror "Module error"
		wok_exit $EXIT_ERR_SYS
	fi
}

wok_module_getAllowedToCascade()
{
	wok_config_get wok modules_cascade_allowed
}

wok_module_getCascadeDefaults()
{
	wok_config_get wok modules_cascade_defaults
}

wok_module_resolveDeps()
{
	local __array_ref="$1"
	local __modules=()
	eval "__modules=(\"\${${1}[@]}\")"
	local __modules_n=${#__modules[@]}
	local __module
	local __dep
	local __ordered=()
	local __ordered_n=0
	local __i=0
	local __eval_values=""

	while [[ $__ordered_n -lt $__modules_n ]]; do
		for __module in "${__modules[@]}"; do
			for __dep in $(wok_module_pdeps "$__module"); do
				if ! array_has __ordered "$__dep"; then
					continue 2
				fi
			done
			array_add __ordered "$__module"
		done

		__ordered_n=${#__ordered[@]}
		if [[ $__i -eq $__ordered_n ]]; then
			wok_perror "Could not resolve module dependency."
			wok_exit $EXIT_ERR_SYS
		fi
		__i=$__ordered_n
	done

	for __module in "${__ordered[@]}"; do
		__eval_values="${__eval_values} $(printf %q "${__module}")"
	done

	eval "${__array_ref}=(${__eval_values})"
}

wok_module_cascade()
{
	local modules_ref="${1}[@]"
	local modules=("${!modules_ref}")
	local action="$2"
	shift 2
	local param=("$@")
	local module

	for module in "${modules[@]}"; do
		wok_module_handle "$module" "$action" "${param[@]}"
	done
}

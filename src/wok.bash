
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

#-----------------------------------------------------------------------
# Configuration
#-----------------------------------------------------------------------

wok_module_list=({{wok_module_list}})
wok_config_file={{wok_config_file}}
wok_repo_path={{wok_repo_path}}
wok_util_path={{wok_util_path}}

#-----------------------------------------------------------------------
# Global definitions
#-----------------------------------------------------------------------

wok_name="Wok"
wok_version="0.3.0"
wok_command="$(basename ${0})"

# Exit statuses
EXIT_SUCCESS=0
EXIT_ERROR_SYSTEM=-1
EXIT_ERROR_USER=1

# Allow cleaning
wok_exit_callbacks=()

#-----------------------------------------------------------------------
# Initialization
#-----------------------------------------------------------------------

# Wok utilities have a higher priority than system commands
export PATH="${wok_util_path}:${PATH}"

#-----------------------------------------------------------------------
# Modules source
#-----------------------------------------------------------------------

{{modules_src}}

#-----------------------------------------------------------------------
# Common functions source
#-----------------------------------------------------------------------

{{common_src}}

#-----------------------------------------------------------------------
# Wok source
#-----------------------------------------------------------------------

{{wok_module_src}}

{{wok_config_src}}

{{wok_repo_src}}

{{wok_domain_src}}

#-----------------------------------------------------------------------
# Wok control
#-----------------------------------------------------------------------

wok_exit()
{
	local exit_status=$1
	local message="$2"
	local callback

	for callback in "${wok_exit_callbacks[@]}"; do
		"$callback" $exit_status
	done

	[[ -n $message ]] && wok_perror "$message"

	exit $exit_status
}

wok_perror()
{
	local message="$1"

	echo "$message" >&2
}

wok_pusage()
{
	local module
	local module_descr
	local psep

	echo "Usage: ${wok_command} [--help|-h] [--version|-v] <command|module> [<args>]"
	echo
	echo "Commands:"
	echo
	echo "    list        List registered domains"
	echo "    add         Add a domain"
	echo "    remove      Remove a domain"
	echo "    help <command|module>"
	echo "                Help about a command or a module"
	echo
	echo "Modules: "
	echo
	for module in "${wok_module_list[@]}"; do
		module="$(echo "$module" | sed 's/_/-/g')"
		module_descr="$(wok_module_describe "$module")"
		if [[ ${#module} -lt 12 ]]; then
			psep="$(printf ' %.0s' $(seq $((12 - ${#module}))))"
		else
			psep="$(printf "\n                ")"
		fi
		echo "    ${module}${psep}${module_descr}"
	done
	echo
}

wok_handle()
{
	local arg
	local arg_value
	local module

	if [[ -z "$*" ]]; then
		wok_pusage
		wok_exit $EXIT_ERROR_USER
	fi

	for arg in "$@"; do
		arg_value="$(arg_parseValue "$arg")"

		case "$arg" in

			-h|--help)
				wok_pusage
				wok_exit $EXIT_SUCCESS;;

			-v|--version)
				echo "${wok_name} version ${wok_version}"
				wok_exit $EXIT_SUCCESS;;

			help)
				shift
				if [[ -z "$1" ]]; then
					wok_perror "Invalid usage of 'help'."
					wok_exit $EXIT_ERROR_USER
				fi
				case "$1" in
					add)       wok_add    --help; wok_exit $EXIT_SUCCESS;;
					rm|remove) wok_remove --help; wok_exit $EXIT_SUCCESS;;
					ls|list)   wok_list   --help; wok_exit $EXIT_SUCCESS;;
					*)
						if [[ -n "$1" ]] && wok_module_has "$1"; then
							wok_module_handle "$1" --help
							wok_exit $EXIT_SUCCESS
						fi;;
				esac
				wok_perror "No available help for '$1'."
				wok_exit $EXIT_ERROR_USER;;

			add)
				shift
				wok_add "$@"
				wok_exit $EXIT_SUCCESS;;

			rm|remove)
				shift
				wok_remove "$@"
				wok_exit $EXIT_SUCCESS;;

			ls|list)
				shift
				wok_list "$@"
				wok_exit $EXIT_SUCCESS;;

			*)
				shift
				module="$(echo "$arg" | sed -e 's/[ \-]/_/g')"

				if ! wok_module_has "$module"; then
					wok_perror "${wok_name}: '${arg}' is not a valid command. See '${wok_command} --help'."
					wok_exit $EXIT_ERROR_USER
				fi

				wok_module_handle "$module" "$@"
				wok_exit $EXIT_SUCCESS;;

		esac
	done
}

#-----------------------------------------------------------------------
# Wok Execution
#-----------------------------------------------------------------------

wok_handle "$@"


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

WOK_MODULE_LIST=({{wok_module_list}})
WOK_CONFIG_FILE={{wok_config_file}}
WOK_REPO_PATH={{wok_repo_path}}
WOK_UTIL_PATH={{wok_util_path}}

#-----------------------------------------------------------------------
# Global definitions
#-----------------------------------------------------------------------

WOK_NAME="Wok"
WOK_VERSION="2.0.0-alpha"
WOK_COMMAND="$(basename ${0})"

# Exit statuses (note: a system error should be fatal)
EXIT_OK=0
EXIT_ERR_SYS=-1
EXIT_ERR_USR=1

# Allow cleaning
wok_exit_callbacks=()

#-----------------------------------------------------------------------
# Initialization
#-----------------------------------------------------------------------

# Wok utilities have a higher priority than system commands
export PATH="${WOK_UTIL_PATH}:${PATH}"

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

{{wok_report_src}}

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

	echo "Usage: ${WOK_COMMAND} [--help|-h] [--version|-v] <command|module> [<args>]"
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
	for module in "${WOK_MODULE_LIST[@]}"; do
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
		wok_exit $EXIT_ERR_USR
	fi

	for arg in "$@"; do
		arg_value="$(arg_parseValue "$arg")"

		case "$arg" in

			-h|--help)
				wok_pusage
				wok_exit $EXIT_OK;;

			-v|--version)
				echo "${WOK_NAME} version ${WOK_VERSION}"
				wok_exit $EXIT_OK;;

			help)
				shift
				if [[ -z "$1" ]]; then
					wok_perror "Invalid usage of 'help'."
					wok_exit $EXIT_ERR_USR
				fi
				case "$1" in
					add)       wok_add    --help; wok_exit $EXIT_OK;;
					rm|remove) wok_remove --help; wok_exit $EXIT_OK;;
					ls|list)   wok_list   --help; wok_exit $EXIT_OK;;
					*)
						if [[ -n "$1" ]] && wok_module_has "$1"; then
							wok_module_handle "$1" --help
							wok_exit $EXIT_OK
						fi;;
				esac
				wok_perror "No available help for '$1'."
				wok_exit $EXIT_ERR_USR;;

			add)
				shift
				wok_add "$@"
				wok_exit $EXIT_OK;;

			rm|remove)
				shift
				wok_remove "$@"
				wok_exit $EXIT_OK;;

			ls|list)
				shift
				wok_list "$@"
				wok_exit $EXIT_OK;;

			*)
				shift
				module="$(echo "$arg" | sed -e 's/[ \-]/_/g')"

				if ! wok_module_has "$module"; then
					wok_perror "${WOK_NAME}: '${arg}' is not a valid command. See '${WOK_COMMAND} --help'."
					wok_exit $EXIT_ERR_USR
				fi

				wok_module_handle "$module" "$@"
				wok_exit $EXIT_OK;;

		esac
	done
}

#-----------------------------------------------------------------------
# Wok Execution
#-----------------------------------------------------------------------

wok_handle "$@"

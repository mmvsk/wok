
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
	local args_remain=()
	local module
	local cmd

	local domain=
	local interactive=false
	local cascade=false
	local cascade_modules=()
	local passwd=
	local passwd_generate=true
	local report_to=

	for arg in "$@"; do
		case "$arg" in

			-h|--help)
				echo "Usage: ${wok_command} add [--interactive|-i] [--password=<password>]"
				echo "               [--cascade|-c] [--with-<module>] [--report-to=<email>]"
				echo "               <domain>"
				echo
				echo "Modules:"
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
				return $EXIT_SUCCESS;;

			-i|--interactive)
				interactive=true;;

			-c|--cascade)
				cascade=true;;

			-p*|--password=*)
				if ! passwd="$(arg_parseValue "$arg")"; then
					wok_perror "Invalid usage."
					wok_exit $EXIT_ERROR_USER
				fi;;

			--with-*)
				module="$(echo ${arg#--with-} | sed -e 's/[ \-]/_/g')"
				if ! wok_module_has "$module"; then
					wok_perror "Invalid module '${module}'."
					wok_exit $EXIT_ERROR_USER
				fi
				if ! array_has cascade_modules[@] "$module"; then
					cascade_modules=("${cascade_modules[@]}" "$module")
				fi;;

			--report-to=*)
				if ! report_to="$(arg_parseValue "$arg")"; then
					wok_perror "Invalid usage."
					wok_exit $EXIT_ERROR_USER
				fi;;

			*)
				args_remain=("${args_remain[@]}" "$arg");;

		esac
	done

	if [[ ${#args_remain[@]} -ne 1 ]]; then
		wok_perror "Invalid usage. See '${wok_command} add --help'."
		wok_exit $EXIT_ERROR_USER
	fi

	domain="${args_remain[0]}"

	if wok_repo_has "$domain"; then
		wok_perror "Domain '${domain}' already exists."
		wok_exit $EXIT_ERROR_USER
	fi

	cmd=(wok_repo_add "$domain")
	if ! ui_showProgress "Adding managed domain '${domain}'" "${cmd[@]}"; then
		wok_exit $EXIT_ERROR_SYSTEM
	fi

	echo "All right!"
}

wok_remove()
{
	echo REMOVE $*
}

wok_list()
{
	echo LIST $*
}

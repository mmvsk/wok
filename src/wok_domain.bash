
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

WOK_DOMAIN_PATTERN='^[[:alnum:]]+([.\-][[:alnum:]]+)*$'
WOK_PASSWD_PATTERN='^[[:alnum:]]{8,64}$'
WOK_PASSWD_LENGTH=12
WOK_PASSWD_CMD="pwgen -s $WOK_PASSWD_LENGTH 1"

wok_add()
{
	local arg
	local arg_value
	local args_remain=()
	local module
	local cmd
	local param=()

	local domain=""
	local interactive=false
	local cascade_defaults=false
	local cascade_list=()
	local passwd=""
	local passwd_generate=true
	local report_to=()
	local print_report=false

	for arg in "$@"; do
		case "$arg" in

			-h|--help)
				echo "Usage: ${wok_command} add [--interactive|-i] [--password=<password>]"
				echo "               [--cascade|-c] [--with-<module>] [--print-report]"
				echo "               [--report-to=<email>] <domain>"
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
				cascade_defaults=true;;

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
				array_add cascade_list "$module";;

			--print-report)
				print_report=true;;

			--report-to=*)
				if ! arg_value="$(arg_parseValue "$arg")"; then
					wok_perror "Invalid usage."
					wok_exit $EXIT_ERROR_USER
				fi
				array_add report_to "$arg_value";;

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

	if ! [[ $domain =~ $WOK_DOMAIN_PATTERN ]]; then
		wok_perror "Domain name '${domain}' is invalid. Please use the following pattern:"
		wok_perror
		wok_perror "    ${WOK_DOMAIN_PATTERN}"
		wok_perror
		wok_exit $EXIT_ERROR_USER
	fi

	if $cascade_defaults; then
		for module in $(wok_module_getDefaults); do
			array_add cascade_list "$module"
		done
	fi
	wok_module_resolveDeps cascade_list

	if ! [[ $passwd =~ $WOK_PASSWD_PATTERN ]]; then
		if $interactive && ! user_confirm "Generate a global password?"; then
			user_getPasswd passwd "$WOK_PASSWD_PATTERN"
		else
			passwd="$($WOK_PASSWD_CMD)"
		fi
	fi

	#
	# Process!
	#

	cmd=(wok_repo_add "$domain")
	if ! ui_showProgress "Adding managed domain '${domain}'" "${cmd[@]}"; then
		wok_exit $EXIT_ERROR_SYSTEM
	fi

	param=()
	$interactive && array_add param "--interactive"
	array_add param "--password=${passwd}"

	wok_module_cascade cascade_list add param "$domain"

	wok_report_create report
	wok_report_printfl report "# Wok Recipe: %s" "$domain"
	wok_report_printl
}

wok_remove()
{
	echo REMOVE $*
}

wok_list()
{
	echo LIST $*
}

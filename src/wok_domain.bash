
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
WOK_LOG_ENABLE=false
WOK_LOG_PATTERN="^/tmp/"

wok_add()
{
	# Argument vars
	local domain=""
	local interactive=false
	local cascade_defaults=false
	local cascade_list=()
	local passwd=""
	local passwd_generate=true
	local report_to=()
	local report_log=""

	# Temp vars
	local arg
	local arg_value
	local args_remain=()
	local module
	local module_name
	local cmd
	local param=()
	local report
	local email
	local email_from
	local re
	# [FIXME] Dirty list to array conversion... Best way: directly use array
	# format in .ini (modules_cascadable[] = ...), and retrieve as an
	# array using an iterator (or new lines). But for this version it's
	# OK. Just be sure that the configuration is valid...
	local cascade_allowed=($(wok_module_getAllowedToCascade))

	# Process arguments
	for arg in "$@"; do
		case "$arg" in

			-h|--help)
				echo "Usage: ${WOK_COMMAND} add [--interactive|-i] [--password=<password>]"
				echo "               [--cascade|-c] [--with-<module>] [--report-log=<file>]"
				echo "               [--report-to=<email>] <domain>"
				echo
				echo "Modules:"
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
				return $EXIT_OK;;

			-i|--interactive)
				interactive=true;;

			-c|--cascade)
				cascade_defaults=true;;

			-p*|--password=*)
				if ! passwd="$(arg_parseValue "$arg")"; then
					wok_perror "Invalid usage."
					wok_exit $EXIT_ERR_USR
				fi;;

			--with-*)
				module="$(echo ${arg#--with-} | sed -e 's/[ \-]/_/g')"
				if ! wok_module_has "$module"; then
					wok_perror "Invalid module '${module}'."
					wok_exit $EXIT_ERR_USR
				fi
				if ! array_has cascade_allowed "$module"; then
					wok_perror "Module '${module}' is not allowed to cascade."
					wok_exit $EXIT_ERR_USR
				fi
				array_add cascade_list "$module";;

			--report-log=*)
				if ! $WOK_LOG_ENABLE; then
					wok_perror "Report logging has been disabled as it presents a security risk."
					wok_exit $EXIT_ERR_USR
				fi
				if ! arg_value="$(arg_parseValue "$arg")"; then
					wok_perror "Invalid usage."
					wok_exit $EXIT_ERR_USR
				fi
				if ! [[ $arg_value =~ $WOK_LOG_PATTERN ]]; then
					wok_perror "The log file must be located in a temp directory."
					wok_exit $EXIT_ERR_USR
				fi
				if [[ ! -f $arg_value ]]; then
					wok_perror "The log file must already be created."
					wok_exit $EXIT_ERR_USR
				fi
				report_log="$arg_value";;

			--report-to=*)
				if ! arg_value="$(arg_parseValue "$arg")"; then
					wok_perror "Invalid usage."
					wok_exit $EXIT_ERR_USR
				fi
				array_add report_to "$arg_value";;

			*)
				args_remain=("${args_remain[@]}" "$arg");;

		esac
	done

	# Only one additional argument is required: the domain name
	if [[ ${#args_remain[@]} -ne 1 ]]; then
		wok_perror "Invalid usage. See '${WOK_COMMAND} add --help'."
		wok_exit $EXIT_ERR_USR
	fi

	# Domain name processing
	domain="${args_remain[0]}"
	if wok_repo_has "$domain"; then
		wok_perror "Domain '${domain}' already exists."
		wok_exit $EXIT_ERR_USR
	fi
	if ! [[ $domain =~ $WOK_DOMAIN_PATTERN ]]; then
		wok_perror "Domain name '${domain}' is invalid. Please use the following pattern:"
		wok_perror
		wok_perror "    ${WOK_DOMAIN_PATTERN}"
		wok_perror
		wok_exit $EXIT_ERR_USR
	fi

	# Determine modules
	if $cascade_defaults; then
		for module in $(wok_module_getCascadeDefaults); do
			array_add cascade_list "$module"
		done
	fi
	if [[ ${#cascade_list[@]} -lt 1 ]] && $interactive; then
		for module in $(wok_module_getAllowedToCascade); do
			module_name="$(wok_module_pname "$module")"
			if ui_confirm "Use '${module_name}'?"; then
				array_add cascade_list "$module"
			fi
		done
	fi
	for module in "${cascade_list[@]}"; do
		if ! array_has cascade_allowed "$module"; then
			wok_perror "Module '${module}' is not allowed to cascade."
			wok_exit $EXIT_ERR_SYS
		fi
	done
	wok_module_resolveDeps cascade_list

	# Create the password
	if ! [[ $passwd =~ $WOK_PASSWD_PATTERN ]]; then
		if $interactive && ! ui_confirm "Generate a global password?"; then
			ui_getPasswd passwd "$WOK_PASSWD_PATTERN"
		else
			passwd="$($WOK_PASSWD_CMD)"
		fi
	fi

	# Determine report recipients
	if [[ ${#report_to[@]} -lt 1 ]] && $interactive; then
		if ui_confirm "Send the recipe via e-mail?"; then
			re='[[:alnum:]._\-]{1,255}@[[:alnum:].\-]{1,255}'
			ui_getString report_to[0] "${re}(,${re}){0,12}" "E-mail (separate by a comma)"
		fi
	fi

	# Register the domain in the repo
	cmd=(wok_repo_add "$domain")
	if ! ui_showProgress "Adding managed domain '${domain}'" "${cmd[@]}"; then
		wok_exit $EXIT_ERR_SYS
	fi

	# Create the report
	wok_report_create report
	wok_report_insl report "Wok recipe: %s" "$domain"
	wok_report_insl report ""

	# Determine module arguments
	param=()
	$interactive && array_add param "--interactive"
	array_add param "--password=${passwd}"
	array_add param "--report-log=${report}"

	# Call the modules
	wok_module_cascade cascade_list add "${param[@]}" "$domain"

	# Log the report
	if [[ -n $report_log ]]; then
		wok_report_print report "$report_log"
	fi

	# Send the report via e-mail
	if [[ ${#report_to[@]} -gt 0 ]]; then
		param=()
		email_from="$(wok_config_get wok report_email_from)"
		[[ -n $email_from ]] && param=("${param[@]}" "$email_from")
		for email in "${report_to[@]}"; do
			wok_report_send report "$email" "Wok recipe: ${domain}" "${param[@]}"
		done
	fi

	# Clean the report
	wok_report_delete report
}

wok_remove()
{
	# Argument vars
	local force=false
	local domain

	# Temp vars
	local arg
	local args_remain=()
	local modules
	local module
	local param=()

	# Process arguments
	for arg in "$@"; do
		case "$arg" in

			-h|--help)
				echo "Usage: ${WOK_COMMAND} remove [--force|-f] <domain>"
				return $EXIT_OK;;

			-f|--force)
				force=true;;

			*)
				args_remain=("${args_remain[@]}" "$arg");;

		esac
	done

	# Only one additional argument is required: the domain name
	if [[ ${#args_remain[@]} -ne 1 ]]; then
		wok_perror "Invalid usage. See '${WOK_COMMAND} remove --help'."
		wok_exit $EXIT_ERR_USR
	fi

	# Domain name processing
	domain="${args_remain[0]}"
	if ! wok_repo_has "$domain"; then
		wok_perror "Domain '${domain}' does not exist."
		wok_exit $EXIT_ERR_USR
	fi

	# Request confirmation
	if ! $force; then
		if ! ui_confirm "$(echo -e \
			"You are going to remove this domain and all associated data, without any\n" \
			"\bpossibility of recovery. Do you really want to continue?" \
		)"; then
			echo "Aborted."
			return $EXIT_OK
		fi
	fi

	# Resolve involved modules
	for module in "${WOK_MODULE_LIST[@]}"; do
		if wok_repo_module_has "$module" "$domain"; then
			array_add modules "$module"
		fi
	done
	wok_module_resolveDeps modules
	array_reverse modules

	# Determine module arguments
	param=()
	$force && array_add param "--force"

	# Call the modules
	wok_module_cascade modules remove "${param[@]}" "$domain"

	# Unregister the domain
	cmd=(wok_repo_remove "$domain")
	if ! ui_showProgress "Removing managed domain '${domain}'" "${cmd[@]}"; then
		wok_exit $EXIT_ERR_SYS
	fi
}

wok_list()
{
	# Argument vars
	local list_modules=false

	# Temp vars
	local arg
	local domain
	local module
	local has_module

	# Process arguments
	for arg in "$@"; do
		case "$arg" in

			-h|--help)
				echo "Usage: ${WOK_COMMAND} list [--with-modules|-m]"
				return $EXIT_OK;;

			-m|--with-modules)
				list_modules=true;;

			*)
				args_remain=("${args_remain[@]}" "$arg");;

		esac
	done

	# No additional arguments are allowed
	if [[ ${#args_remain[@]} -ne 0 ]]; then
		wok_perror "Invalid usage. See '${WOK_COMMAND} list --help'."
		wok_exit $EXIT_ERR_USR
	fi

	# Print managed domains
	if ! $list_modules; then
		# ...without modules
		wok_repo_list
	else
		# ...with modules
		for domain in $(wok_repo_list); do
			has_module=false
			echo -n "${domain} "
			for module in "${WOK_MODULE_LIST[@]}"; do
				if wok_repo_module_has "$module" "$domain"; then
					if ! $has_module; then
						has_module=true
						echo -n "("
					else
						echo -n ", "
					fi
					echo -n "${module}"
				fi
			done
			if $has_module; then
				echo -n ")"
			fi
			echo
		done
	fi
}

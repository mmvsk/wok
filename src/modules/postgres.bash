
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
# License along with Wok. If not, see <http://postgres.gnu.org/licenses/>.
#

wok_postgres_describe()
{
	echo "The postgres module handles the postgres HTTP server configuration"
}

wok_postgres_pdeps()
{
	echo www
}

wok_postgres_pusage()
{
	echo "Usage: ${WOK_COMMAND} postgres [--help|-h] <command> [<args>]"
	echo
	echo "Commands:"
	echo
	echo "    list        List domain handled by this module"
	echo "    add         Add a domain to this module"
	echo
	echo "        Usage: ~ [--interactive|-i] [--password=<password>|-p<password>]"
	echo "                 <domain>"
	echo
	echo "    remove      Remove a domain"
	echo
	echo "        Usage: ~ [--force|-f] <domain>"
	echo
}

wok_postgres_add()
{
	local domain="$1"
	local interactive="$2"
	local password="$3"

	local uid
	local uid_index
	local user_gid="$(wok_config_get wok_postgres user_gid)"
	local user_shell="$(wok_config_get wok_postgres user_shell)"
	local home_path_base="$(wok_config_get wok_postgres home_path_base)"
	local postgres_path_base="$(wok_config_get wok_postgres postgres_path_base)"
	local home_template="$(wok_config_get wok_postgres home_template_path)"
	local postgres_template="$(wok_config_get wok_postgres postgres_template_path)"
	local home_path
	local postgres_path
	local umask_prev

	if ! wok_repo_has "$domain"; then
		wok_perror "Domain '${domain}' is not managed by Wok."
		wok_exit $EXIT_ERR_USR
	fi

	if wok_postgres_has "$domain"; then
		wok_perror "Domain '${domain}' is already bound to 'postgres' module."
		wok_exit $EXIT_ERR_USR
	fi

	# Generate system UID
	uid_index="$(wok_repo_module_index_getPath postgres uid)"
	if ! uid="$(str_slugify "$domain" 32 "postgres-" "$uid_index")"; then
		wok_perror "Could not create a slug for '${domain}'"
		wok_exit $EXIT_ERR_SYS
	fi

	# Verify base paths
	if [[ ! -d "$home_path_base" || ! -w "$home_path_base" ]]; then
		wok_perror "Home base directory '${home_path_base}' does not exist or is not writable."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -d "$postgres_path_base" || ! -w "$postgres_path_base" ]]; then
		wok_perror "WWW base directory '${postgres_path_base}' does not exist or is not writable."
		wok_exit $EXIT_ERR_SYS
	fi

	# Generate paths
	home_path="${home_path_base}/${uid}"
	postgres_path="${postgres_path_base}/${domain}"

	# Verify paths availability
	if [[ -e "$home_path" ]]; then
		wok_perror "Home directory '${home_path}' already exists."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ -e "$postgres_path" ]]; then
		wok_perror "WWW directory '${postgres_path}' already exists."
		wok_exit $EXIT_ERR_SYS
	fi

	# Verify templates existence
	if [[ ! -e "$home_template" ]]; then
		wok_perror "Home template '${home_template}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -e "$postgres_template" ]]; then
		wok_perror "WWW template '${postgres_template}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi

	# Create system user
	if ! useradd -g "$user_gid" -d "$home_path" -s "$user_shell" "$uid"; then
		wok_perror "Could not create system user '${uid}'."
		wok_exit $EXIT_ERR_SYS
	fi

	# Create postgres direcotry
	umask_prev="$(umask)"
	umask "$(wok_config_get wok_postgres postgres_umask)"
	if ! cp -r "$postgres_template" "$postgres_path"; then
		wok_perror "Could not create postgres directory '${postgres_path}'."
		wok_exit $EXIT_ERR_SYS
	fi
	chown -R "${uid}:${user_gid}" "$postgres_path"
	umask "$umask_prev"

	# Create home directory
	umask_prev="$(umask)"
	umask "$(wok_config_get wok_postgres home_umask)"
	if ! cp -r "$home_template" "$home_path"; then
		wok_perror "Could not create home directory '${home_path}'."
		wok_exit $EXIT_ERR_SYS
	fi
	ln -s "$postgres_path" "${home_path}/postgres"
	chmod -R 700 "${home_path}/.ssh"
	chown -R "${uid}:${user_gid}" "$home_path"
	umask "$umask_prev"

	# Register...
	wok_repo_module_add "postgres" "$domain"
	wok_repo_module_index_add "postgres" "uid" "$uid"
	wok_repo_module_data_set "postgres" "$domain" "uid" "$uid"
}

wok_postgres_has()
{
	local domain="$1"

	wok_repo_module_has postgres "$domain"
}

wok_postgres_list()
{
	wok_repo_module_list postgres | sort
}

wok_postgres_remove()
{
	local domain="$1"

	local uid
	local home_path
	local postgres_path

	if ! wok_postgres_has "$domain"; then
		wok_perror "Domain '${domain}' is not bound to 'postgres' module."
		wok_exit $EXIT_ERR_USR
	fi

	uid="$(wok_postgres_puid "$domain")"
	home_path="$(wok_config_get wok_postgres home_path_base)/${uid}"
	postgres_path="$(wok_config_get wok_postgres postgres_path_base)/${domain}"

	if ! egrep -q "^${uid}:" /etc/passwd; then
		wok_perror "System user '${uid}' does not exist on this host."
		wok_exit $EXIT_ERR_SYS
	fi

	if [[ ! -d $home_path ]]; then
		wok_perror "Home directory '${home_path}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -d $postgres_path ]]; then
		wok_perror "WWW directory '${postgres_path}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi

	if ! $WOK_WWW_USERDEL_CMD "$uid"; then
		wok_perror "Error deleting system user '${uid}'"
		wok_exit $EXIT_ERR_SYS
	fi

	if [[ -d $home_path ]]; then
		rm -rf "$home_path"
	fi
	rm -rf "$postgres_path"

	# Unregister...
	wok_repo_module_remove "postgres" "$domain"
	wok_repo_module_index_remove "postgres" "uid" "$uid"
	wok_repo_module_data_remove "postgres" "$domain"
}

wok_postgres_puid()
{
	local domain="$1"

	if ! wok_postgres_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'postgres' module."
		wok_exit $WOK_ERR_SYS
	fi

	wok_repo_module_data_get "postgres" "$domain" "uid"
}

wok_postgres_handle()
{
	# Argument vars
	local action=""
	local domain=""
	local interactive=false
	local passwd=""
	local report_log=""
	local force=false

	# Temp vars
	local arg
	local arg_value
	local args_remain=()
	local retval

	# Process arguments
	for arg in "$@"; do
		case "$arg" in

			-h|--help)
				wok_postgres_pusage;;

			-i|--interactive)
				interactive=true;;

			-p*|--password=*)
				if ! passwd="$(arg_parseValue "$arg")"; then
					wok_perror "Invalid usage."
					wok_exit $EXIT_ERR_USR
				fi;;

			-f|--force)
				force=true;;

			--report-log=*)
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

			*)
				args_remain=("${args_remain[@]}" "$arg");;

		esac
	done

	# Call handler!!

	# At least one argument is required: the action to perform
	if [[ ${#args_remain[@]} -lt 1 ]]; then
		wok_perror "Invalid usage. See '${WOK_COMMAND} postgres --help'."
		wok_exit $EXIT_ERR_USR
	fi

	# Get the action
	array_shift args_remain action

	case "$action" in

		add)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} postgres --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			cmd=(wok_postgres_add "$domain" "$interactive" "$password")
			if ! ui_showProgress "Binding domain '${domain}' to 'postgres' module" "${cmd[@]}"; then
				return 1
			fi

			if [[ -n $report_log ]]; then
				wok_report_insl report_log "postgres:"
				wok_report_insl report_log "    uid: %s" "$(wok_repo_module_data_get "postgres" "$domain" "uid")"
			fi;;

		list|ls)
			wok_postgres_list
			return $?;;

		remove|rm)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} postgres --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			if ! $force && ! ui_confirm "You are about to delete all files related to ${domain}. Continue?"; then
				echo "Aborted."
				return 0
			fi

			cmd=(wok_postgres_remove "$domain")
			ui_showProgress "Unbinding domain '${domain}' from 'postgres' module" "${cmd[@]}"
			return $?;;

		*)
			wok_perror "Invalid usage. See '${WOK_COMMAND} postgres --help'."
			wok_exit $EXIT_ERR_USR;;

	esac
}


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
# License along with Wok. If not, see <http://mysql.gnu.org/licenses/>.
#

wok_mysql_describe()
{
	echo "The mysql module handles the MySQL database"
}

wok_mysql_pdeps()
{
	echo www
}

wok_mysql_pusage()
{
	echo "Usage: ${WOK_COMMAND} mysql [--help|-h] <command> [<args>]"
	echo
	echo "Commands:"
	echo
	echo "    list        List domain handled by this module"
	echo "    add         Add a domain to this module (and create a user and a database)"
	echo
	echo "        Usage: ~ [--interactive|-i] [--password=<password>|-p<password>]"
	echo "                 <domain>"
	echo
	echo "    remove      Remove a domain"
	echo
	echo "        Usage: ~ [--force|-f] <domain>"
	echo
}

wok_mysql_add()
{
	local domain="$1"
	local interactive="$2"
	local passwd="$3"

	local uid
	local uid_index
	local db
	local db_index

	if ! wok_repo_has "$domain"; then
		wok_perror "Domain '${domain}' is not managed by Wok."
		wok_exit $EXIT_ERR_USR
	fi

	if wok_mysql_has "$domain"; then
		wok_perror "Domain '${domain}' is already bound to 'mysql' module."
		wok_exit $EXIT_ERR_USR
	fi

	# Generate the username
	uid_index="$(wok_repo_module_index_getPath mysql uid)"
	if ! uid="$(str_slugify "$domain" 16 "www_" "$uid_index")"; then
		wok_perror "Could not create a slug for the mysql user for '${domain}'"
		wok_exit $EXIT_ERR_SYS
	fi

	# Generate the dbname
	db_index="$(wok_repo_module_index_getPath mysql db)"
	if ! db="$(str_slugify "$domain" 32 "www_" "$db_index")"; then
		wok_perror "Could not create a slug for the mysql db for '${domain}'"
		wok_exit $EXIT_ERR_SYS
	fi

	# Verify user and database availability
	#TODO implement

	# If the password is not provided, first try to get the one from www, then ask it
	if [[ -z $passwd ]]; then
		passwd="$(wok_www_getPassword "$domain")"
		if [[ -z $passwd ]]; then
			if ! $interactive; then
				wok_perror "No password available and not in interactive mode"
				wok_exit $EXIT_ERR_USR
			fi
			ui_getPasswd passwd "$WOK_PASSWD_PATTERN"
		fi
	fi

	# Create user and database
	wok_mysql_query "create user \`$uid\`@'%' identified by '$passwd'"
	wok_mysql_query "create database \`$db\` default character set 'utf8' default collate 'utf8_general_ci'"
	wok_mysql_query "grant all privileges on \`$db\`.* to \`$uid\`@'%' identified by '$passwd'"
	wok_mysql_query "flush privileges"

	# Register...
	wok_repo_module_add "mysql" "$domain"
	wok_repo_module_index_add "mysql" "uid" "$uid"
	wok_repo_module_index_add "mysql" "db"  "$db"
	wok_repo_module_data_set "mysql" "$domain" "uid" "$uid"
	wok_repo_module_data_set "mysql" "$domain" "db"  "$db"
}

wok_mysql_query()
{
	local query="$1"
	local root_passwd="$(wok_config_get wok_mysql root_passwd)"

	echo "$query" | mysql -u root --password="$root_passwd"
}

wok_mysql_has()
{
	local domain="$1"

	wok_repo_module_has mysql "$domain"
}

wok_mysql_list()
{
	wok_repo_module_list mysql | sort
}

wok_mysql_remove()
{
	local domain="$1"

	local uid
	local db

	if ! wok_mysql_has "$domain"; then
		wok_perror "Domain '${domain}' is not bound to 'mysql' module."
		wok_exit $EXIT_ERR_USR
	fi

	uid="$(wok_mysql_getUid "$domain")"
	db="$(wok_mysql_getDb "$domain")"

	# Implement existence check

	wok_mysql_query "drop database ${db}"
	wok_mysql_query "drop user ${uid}"

	wok_mysql_query "drop database if exists \`$db\`"
	wok_mysql_query "drop user \`$uid\`"
	wok_mysql_query "flush privileges"

	# Unregister...
	wok_repo_module_remove "mysql" "$domain"
	wok_repo_module_index_remove "mysql" "uid" "$uid"
	wok_repo_module_data_remove "mysql" "$domain"
}

wok_mysql_getUid()
{
	local domain="$1"

	if ! wok_mysql_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'mysql' module."
		wok_exit $WOK_ERR_SYS
	fi

	wok_repo_module_data_get "mysql" "$domain" "uid"
}

wok_mysql_getDb()
{
	local domain="$1"

	if ! wok_mysql_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'mysql' module."
		wok_exit $WOK_ERR_SYS
	fi

	wok_repo_module_data_get "mysql" "$domain" "db"
}

wok_mysql_handle()
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
				wok_mysql_pusage;;

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
		wok_perror "Invalid usage. See '${WOK_COMMAND} mysql --help'."
		wok_exit $EXIT_ERR_USR
	fi

	# Get the action
	array_shift args_remain action

	case "$action" in

		add)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} mysql --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			cmd=(wok_mysql_add "$domain" "$interactive" "$passwd")
			if ! ui_showProgress "Binding domain '${domain}' to 'mysql' module" "${cmd[@]}"; then
				return 1
			fi

			if [[ -n $report_log ]]; then
				wok_report_insl report_log "mysql:"
				wok_report_insl report_log "    uid: %s" "$(wok_repo_module_data_get "mysql" "$domain" "uid")"
			fi;;

		list|ls)
			wok_mysql_list
			return $?;;

		remove|rm)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} mysql --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			if ! $force && ! ui_confirm "You are about to delete all files related to ${domain}. Continue?"; then
				echo "Aborted."
				return 0
			fi

			cmd=(wok_mysql_remove "$domain")
			ui_showProgress "Unbinding domain '${domain}' from 'mysql' module" "${cmd[@]}"
			return $?;;

		*)
			wok_perror "Invalid usage. See '${WOK_COMMAND} mysql --help'."
			wok_exit $EXIT_ERR_USR;;

	esac
}

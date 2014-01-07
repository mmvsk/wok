
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
	echo "The postgres module handles the PostgreSQL database"
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

wok_postgres_add()
{
	local domain="$1"
	local interactive="$2"
	local passwd="$3"

	local uid
	local uid_index
	local db
	local db_index
	local master_user="$(wok_config_get wok_postgres master_user)"
	local pgpass_template="$(wok_config_get wok_postgres pgpass_template)"
	local pgpass_file="$(wok_config_get wok_postgres pgpass_file)"
	local pgpass_path
	local shellrc_template="$(wok_config_get wok_postgres shellrc_template)"
	local shellrc_path
	local sys_uid="$(wok_www_getUid "$domain")"
	local sys_gid="$(wok_www_getGid "$domain")"
	local home_path="$(wok_www_getHomePath "$domain")"

	if ! wok_repo_has "$domain"; then
		wok_perror "Domain '${domain}' is not managed by Wok."
		wok_exit $EXIT_ERR_USR
	fi

	if wok_postgres_has "$domain"; then
		wok_perror "Domain '${domain}' is already bound to 'postgres' module."
		wok_exit $EXIT_ERR_USR
	fi

	# Generate the username
	uid_index="$(wok_repo_module_index_getPath postgres uid)"
	if ! uid="$(str_slugify "$domain" 32 "www_" "$uid_index")"; then
		wok_perror "Could not create a slug for the postgres user for '${domain}'"
		wok_exit $EXIT_ERR_SYS
	fi

	# Generate the dbname
	db_index="$(wok_repo_module_index_getPath postgres db)"
	if ! db="$(str_slugify "$domain" 63 "www_" "$db_index")"; then
		wok_perror "Could not create a slug for the postgres db for '${domain}'"
		wok_exit $EXIT_ERR_SYS
	fi

	# Verify user and database availability
	if wok_postgres_query "select '__exists__' from pg_roles where rolname = '${uid}'" | grep -q __exists__; then
		wok_perror "Postgres user '${uid}' already exists."
		wok_exit $EXIT_ERR_SYS
	fi
	if wok_postgres_query "select '__exists__' from pg_database where datname = '${db}'" | grep -q __exists__; then
		wok_perror "Postgres database '${db}' already exists."
		wok_exit $EXIT_ERR_SYS
	fi

	# Verify templates existence
	if [[ ! -e "$pgpass_template" ]]; then
		wok_perror "PgPass template '${pgpass_template}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -e "$shellrc_template" ]]; then
		wok_perror "Shell RunCom template '${shellrc_template}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi

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
	wok_postgres_query "create user ${uid} with encrypted password '${passwd}'"
	wok_postgres_query "create database ${db} owner ${uid}"

	# Add home files
	pgpass_path="${home_path}/${pgpass_file}"
	shellrc_path="$(wok_www_getModuleRcPath "$domain" "postgres")"

	cp "$pgpass_template" "$pgpass_path"
	sed -i "s/{uid}/${uid}/g" "$pgpass_path"
	sed -i "s/{passwd}/${passwd}/g" "$pgpass_path"
	chown "${sys_uid}:${sys_gid}" "$pgpass_path"
	chmod 600 "$pgpass_path"

	cp "$shellrc_template" "$shellrc_path"
	sed -i "s/{uid}/${uid}/g" "$shellrc_path"
	chown "${sys_uid}:${sys_gid}" "$shellrc_path"
	chmod 600 "$shellrc_path"

	# Register...
	wok_repo_module_add "postgres" "$domain"
	wok_repo_module_index_add "postgres" "uid" "$uid"
	wok_repo_module_index_add "postgres" "db"  "$db"
	wok_repo_module_data_set "postgres" "$domain" "uid" "$uid"
	wok_repo_module_data_set "postgres" "$domain" "db"  "$db"
}

wok_postgres_query()
{
	local query="$1"
	local master_user="$(wok_config_get wok_postgres master_user)"
	local ret

	echo "$query" | sudo -u "$master_user" psql
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
	local db

	if ! wok_postgres_has "$domain"; then
		wok_perror "Domain '${domain}' is not bound to 'postgres' module."
		wok_exit $EXIT_ERR_USR
	fi

	uid="$(wok_postgres_getUid "$domain")"
	db="$(wok_postgres_getDb "$domain")"

	if ! wok_postgres_query "select '__exists__' from pg_roles where rolname = '${uid}'" | grep -q __exists__; then
		wok_perror "Postgres user '${uid}' doest not exist"
		wok_exit $EXIT_ERR_SYS
	fi
	if ! wok_postgres_query "select '__exists__' from pg_database where datname = '${db}'" | grep -q __exists__; then
		wok_perror "Postgres database '${db}' does not exist"
		wok_exit $EXIT_ERR_SYS
	fi

	wok_postgres_query "drop database ${db}"
	wok_postgres_query "drop user ${uid}"

	#TODO also remove .pgpass and so on...

	# Unregister...
	wok_repo_module_remove "postgres" "$domain"
	wok_repo_module_index_remove "postgres" "uid" "$uid"
	wok_repo_module_data_remove "postgres" "$domain"
}

wok_postgres_getUid()
{
	local domain="$1"

	if ! wok_postgres_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'postgres' module."
		wok_exit $WOK_ERR_SYS
	fi

	wok_repo_module_data_get "postgres" "$domain" "uid"
}

wok_postgres_getDb()
{
	local domain="$1"

	if ! wok_postgres_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'postgres' module."
		wok_exit $WOK_ERR_SYS
	fi

	wok_repo_module_data_get "postgres" "$domain" "db"
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

			cmd=(wok_postgres_add "$domain" "$interactive" "$passwd")
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

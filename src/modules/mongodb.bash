
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
# License along with Wok. If not, see <http://mongodb.gnu.org/licenses/>.
#

wok_mongodb_describe()
{
	echo "The mongodb module handles the Mongo database"
}

wok_mongodb_pdeps()
{
	echo www
}

wok_mongodb_pusage()
{
	echo "Usage: ${WOK_COMMAND} mongodb [--help|-h] <command> [<args>]"
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

wok_mongodb_add()
{
	local domain="$1"
	local interactive="$2"
	local passwd="$3"

	local uid
	local uid_index
	local db
	local db_index
	local shellrc_template="$(wok_config_get wok_mongodb shellrc_template)"
	local shellrc_path
	local sys_uid="$(wok_www_getUid "$domain")"
	local sys_gid="$(wok_www_getGid "$domain")"

	if ! wok_repo_has "$domain"; then
		wok_perror "Domain '${domain}' is not managed by Wok."
		wok_exit $EXIT_ERR_USR
	fi

	if wok_mongodb_has "$domain"; then
		wok_perror "Domain '${domain}' is already bound to 'mongodb' module."
		wok_exit $EXIT_ERR_USR
	fi

	# Generate the username
	uid_index="$(wok_repo_module_index_getPath mongodb uid)"
	if ! uid="$(str_slugify "$domain" 32 "www_" "$uid_index")"; then
		wok_perror "Could not create a slug for the mongodb user for '${domain}'"
		wok_exit $EXIT_ERR_SYS
	fi

	# Generate the dbname
	db_index="$(wok_repo_module_index_getPath mongodb db)"
	if ! db="$(str_slugify "$domain" 64 "www_" "$db_index")"; then
		wok_perror "Could not create a slug for the mongodb db for '${domain}'"
		wok_exit $EXIT_ERR_SYS
	fi

	# Verify user and database availability
	#TODO implement

	# Verify templates existence
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
	wok_mongodb_query "use ${db}\ndb.addUser('${uid}', '${passwd}');"

	# Add home files
	shellrc_path="$(wok_www_getModuleRcPath "$domain" "mongodb")"
	cp "$shellrc_template" "$shellrc_path"
	sed -i "s/{uid}/${uid}/g" "$shellrc_path"
	sed -i "s/{passwd}/${passwd}/g" "$shellrc_path"
	sed -i "s/{db}/${db}/g" "$shellrc_path"
	chown "${sys_uid}:${sys_gid}" "$shellrc_path"
	chmod 600 "$shellrc_path"

	# Register...
	wok_repo_module_add "mongodb" "$domain"
	wok_repo_module_index_add "mongodb" "uid" "$uid"
	wok_repo_module_index_add "mongodb" "db"  "$db"
	wok_repo_module_data_set "mongodb" "$domain" "uid" "$uid"
	wok_repo_module_data_set "mongodb" "$domain" "db"  "$db"
}

wok_mongodb_query()
{
	local query="$1"

	echo -e "$query" | mongo
}

wok_mongodb_has()
{
	local domain="$1"

	wok_repo_module_has mongodb "$domain"
}

wok_mongodb_list()
{
	wok_repo_module_list mongodb | sort
}

wok_mongodb_remove()
{
	local domain="$1"

	local uid
	local db

	if ! wok_mongodb_has "$domain"; then
		wok_perror "Domain '${domain}' is not bound to 'mongodb' module."
		wok_exit $EXIT_ERR_USR
	fi

	uid="$(wok_mongodb_getUid "$domain")"
	db="$(wok_mongodb_getDb "$domain")"

	# Implement existence check

	wok_mongodb_query "use ${db}\ndb.dropDatabase();"

	# Unregister...
	wok_repo_module_remove "mongodb" "$domain"
	wok_repo_module_index_remove "mongodb" "uid" "$uid"
	wok_repo_module_index_remove "mongodb" "db"  "$db"
	wok_repo_module_data_remove "mongodb" "$domain"
}

wok_mongodb_getUid()
{
	local domain="$1"

	if ! wok_mongodb_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'mongodb' module."
		wok_exit $WOK_ERR_SYS
	fi

	wok_repo_module_data_get "mongodb" "$domain" "uid"
}

wok_mongodb_getDb()
{
	local domain="$1"

	if ! wok_mongodb_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'mongodb' module."
		wok_exit $WOK_ERR_SYS
	fi

	wok_repo_module_data_get "mongodb" "$domain" "db"
}

wok_mongodb_handle()
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
				wok_mongodb_pusage;;

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
		wok_perror "Invalid usage. See '${WOK_COMMAND} mongodb --help'."
		wok_exit $EXIT_ERR_USR
	fi

	# Get the action
	array_shift args_remain action

	case "$action" in

		add)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} mongodb --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			cmd=(wok_mongodb_add "$domain" "$interactive" "$passwd")
			if ! ui_showProgress "Binding domain '${domain}' to 'mongodb' module" "${cmd[@]}"; then
				return 1
			fi

			if [[ -n $report_log ]]; then
				wok_report_insl report_log "mongodb:"
				wok_report_insl report_log "    uid: %s" "$(wok_repo_module_data_get "mongodb" "$domain" "uid")"
			fi;;

		list|ls)
			wok_mongodb_list
			return $?;;

		remove|rm)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} mongodb --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			if ! $force && ! ui_confirm "You are about to delete all files related to ${domain}. Continue?"; then
				echo "Aborted."
				return 0
			fi

			cmd=(wok_mongodb_remove "$domain")
			ui_showProgress "Unbinding domain '${domain}' from 'mongodb' module" "${cmd[@]}"
			return $?;;

		*)
			wok_perror "Invalid usage. See '${WOK_COMMAND} mongodb --help'."
			wok_exit $EXIT_ERR_USR;;

	esac
}

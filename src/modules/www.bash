
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

wok_www_pname()
{
	echo "www domain"
}

wok_www_describe()
{
	echo "The www module handles system users and directories"
}

wok_www_pdeps()
{
	echo
}

wok_www_pusage()
{
	echo "Usage: ${WOK_COMMAND} www [--help|-h] <command> [<args>]"
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

wok_www_add()
{
	local domain="$1"
	local interactive="$2"
	local password="$3"

	local uid
	local uid_index
	local user_gid="$(wok_config_get wok_www user_gid)"
	local user_shell="$(wok_config_get wok_www user_shell)"
	local home_path_base="$(wok_config_get wok_www home_path_base)"
	local www_path_base="$(wok_config_get wok_www www_path_base)"
	local home_path
	local www_path
	local umask_prev

	if ! wok_repo_has "$domain"; then
		wok_perror "Domain '${domain}' is not managed by Wok."
		wok_exit $EXIT_ERR_USR
	fi

	if wok_repo_module_has www "$domain"; then
		wok_perror "Domain '${domain}' is already bound to 'www' module."
		wok_exit $EXIT_ERR_USR
	fi

	# Generate system UID
	uid_index="$(wok_repo_module_index_getPath www uid)"
	if ! uid="$(str_slugify "$domain" 32 "www-" "$uid_index")"; then
		wok_perror "Could not create a slug for '${domain}'"
		wok_exit $EXIT_ERR_SYS
	fi

	# Verify base paths
	#if [[ ! -d "$home_path_base" || ! -w "$home_path_base" ]]; then
		#wok_perror "Home base directory '${home_path_base}' does not exist or is not writable."
		#wok_exit $EXIT_ERR_SYS
	#fi
	#if [[ ! -d "$www_path_base" || ! -w "$www_path_base" ]]; then
		#wok_perror "WWW base directory '${www_path_base}' does not exist or is not writable."
		#wok_exit $EXIT_ERR_SYS
	#fi

	# Generate paths
	home_path="${home_path}/${uid}"
	www_path="${www_path}/${domain}"

	# Verify paths availability
	if [[ -e "$home_path" ]]; then
		wok_perror "Home directory '${home_path}' already exists."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ -e "$www_path" ]]; then
		wok_perror "WWW directory '${www_path}' already exists."
		wok_exit $EXIT_ERR_SYS
	fi

	# Create system user
	#if ! useradd -g "$user_gid" -d "$home_path" -s "$user_shell" "$uid"; then
		#wok_perror "Could not create system user '${uid}'."
		#wok_exit $EXIT_ERR_SYS
	#fi
		echo useradd -g "$user_gid" -d "$home_path" -s "$user_shell" "$uid"

	# Create www direcotry
	#umask_prev="$(umask)"
	#umask "$(wok_config_get wok_www www_umask)"
	#if ! cp -r "$(wok_config_get wok_www www_template_path)" "$www_path"; then
		#wok_perror "Could not create www directory '${www_path}'."
		#wok_exit $EXIT_ERR_SYS
	#fi
	#chown -R "${uid}:${user_gid}" "$www_path"
	#umask "$umask_prev"
		echo umask "$(wok_config_get wok_www www_umask)"
		echo cp -r "$(wok_config_get wok_www www_template_path)" "$www_path"
		echo chown -R "${uid}:${user_gid}" "$www_path"

	# Create home directory
	#umask_prev="$(umask)"
	#umask "$(wok_config_get wok_www home_umask)"
	#if ! cp -r "$(wok_config_get wok_www home_template_path)" "$home_path"; then
		#wok_perror "Could not create home directory '${home_path}'."
		#wok_exit $EXIT_ERR_SYS
	#fi
	#ln -s "$www_path" "${home_path}/www"
	#chmod -R 700 "${home_path}/.ssh"
	#chown -R "${uid}:${user_gid}" "$home_path"
	#umask "$umask_prev"
		echo cp -r "$(wok_config_get wok_www home_template_path)" "$home_path"
		echo ln -s "$www_path" "${home_path}/www"
		echo chmod -R 700 "${home_path}/.ssh"
		echo chown -R "${uid}:${user_gid}" "$home_path"

	# Register...
	wok_repo_module_add "www" "$domain"
	wok_repo_module_index_add "www" "uid" "$uid"
	wok_repo_module_data_set "www" "$domain" "uid" "$uid"
}

wok_www_list()
{
	echo
}

wok_www_remove()
{
	echo
}

wok_www_puid()
{
	echo "Get the uid (there is no CLI interface to this function)"
}

wok_www_handle()
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
				wok_www_pusage;;

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
		wok_perror "Invalid usage. See '${WOK_COMMAND} www --help'."
		wok_exit $EXIT_ERR_USR
	fi

	# Get the action
	array_shift args_remain action

	case "$action" in

		add)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} www --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			cmd=(wok_www_add "$domain" "$interactive" "$password")
			if ! ui_showProgress "Binding domain '${domain}' to 'www' module" "${cmd[@]}"; then
				return 1
			fi

			if [[ -n $report_log ]]; then
				echo "www:" >>"$report_log"
				echo "    uid: $(wok_repo_module_data_get "www" "$domain" "uid")" >>"$report_log"
				echo >>"$report_log"
			fi;;

		list|ls)
			return $?;;

		remove|rm)
			return $?;;

		*)
			wok_perror "Invalid usage. See '${WOK_COMMAND} www --help'."
			wok_exit $EXIT_ERR_USR;;

	esac

	# Domain name processing
	domain="${args_remain[0]}"
}

_____()
{
	case $action in
		ls)
			silent cd $repo
			find . -maxdepth 1 -type f -name "$pattern" \
				| sed -r 's/^.{2}//' \
				| sort
			silent cd -
			;;
		add)
			;;
		rm)
			test ! -e $index_domain/$domain \
				&& echo "This domain does not exist" \
				&& exit 1
			if test ! $force; then
				confirm "Remove www data?" || exit 0
			fi
			source $repo/$domain
			echo -n "Removing system user: $_uid... "
				silent userdel -f $_uid &>> /dev/null
				echo "done"
			echo -n "Removing log directory: $wok_www_log_path/$domain... "
				rm -rf $wok_www_log_path/$domain
				echo "done"
			echo -n "Removing directory: $wok_www_path/$domain... "
				rm -rf $wok_www_path/$domain
				echo "done"
			rm $index_domain/$_domain
			rm $index_uid/$_uid
			rm $repo/$domain
			;;
		uid)
			test ! -e $index_domain/$domain \
				&& echo "This domain does not exist" \
				&& exit 1
			source $repo/$domain
			echo $_uid
			;;
	esac
}

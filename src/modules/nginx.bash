
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
# License along with Wok. If not, see <http://nginx.gnu.org/licenses/>.
#

wok_nginx_describe()
{
	echo "The nginx module handles the nginx HTTP server configuration"
}

wok_nginx_pdeps()
{
	echo www
}

wok_nginx_pusage()
{
	echo "Usage: ${WOK_COMMAND} nginx [--help|-h] <command> [<args>]"
	echo
	echo "Commands:"
	echo
	echo "    list        List domain handled by this module"
	echo "    add         Add a domain to this module"
	echo
	echo "        Usage: ~ [--interactive|-i] <domain>"
	echo
	echo "    remove      Remove a domain"
	echo
	echo "        Usage: ~ [--force|-f] <domain>"
	echo
}

wok_nginx_add()
{
	local domain="$1"
	local interactive="$2"

	local www_path
	local nginx_vhost_template="$(wok_config_get wok_www nginx_vhost_template)"
	local nginx_vhost_dir="$(wok_config_get wok_www nginx_vhost_dir)"

	if ! wok_repo_has "$domain"; then
		wok_perror "Domain '${domain}' is not managed by Wok."
		wok_exit $EXIT_ERR_USR
	fi

	if ! wok_www_has "$domain"; then
		wok_perror "Domain '${domain}' is not bound to module 'www'."
		wok_exit $EXIT_ERR_USR
	fi

	if wok_nginx_has "$domain"; then
		wok_perror "Domain '${domain}' is already bound to 'nginx' module."
		wok_exit $EXIT_ERR_USR
	fi

	www_path="$(wok_www_getWwwPath "$domain")"

	cp "$nginx_vhost_template" "${nginx_vhost_dir}/${domain}.conf"

	# Register...
	wok_repo_module_add "nginx" "$domain"
}

wok_nginx_has()
{
	local domain="$1"

	wok_repo_module_has nginx "$domain"
}

wok_nginx_list()
{
	wok_repo_module_list nginx | sort
}

wok_nginx_remove()
{
	local domain="$1"

	local uid
	local home_path
	local nginx_path

	if ! wok_nginx_has "$domain"; then
		wok_perror "Domain '${domain}' is not bound to 'nginx' module."
		wok_exit $EXIT_ERR_USR
	fi

	uid="$(wok_nginx_puid "$domain")"
	home_path="$(wok_config_get wok_www home_path_base)/${uid}"
	nginx_path="$(wok_config_get wok_www nginx_path_base)/${domain}"

	if ! egrep -q "^${uid}:" /etc/passwd; then
		wok_perror "System user '${uid}' does not exist on this host."
		wok_exit $EXIT_ERR_SYS
	fi

	if [[ ! -d $home_path ]]; then
		wok_perror "Home directory '${home_path}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -d $nginx_path ]]; then
		wok_perror "WWW directory '${nginx_path}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi

	if ! $WOK_WWW_USERDEL_CMD "$uid"; then
		wok_perror "Error deleting system user '${uid}'"
		wok_exit $EXIT_ERR_SYS
	fi

	if [[ -d $home_path ]]; then
		rm -rf "$home_path"
	fi
	rm -rf "$nginx_path"

	# Unregister...
	wok_repo_module_remove "nginx" "$domain"
	wok_repo_module_index_remove "nginx" "uid" "$uid"
	wok_repo_module_data_remove "nginx" "$domain"
}

wok_nginx_handle()
{
	# Argument vars
	local action=""
	local domain=""
	local interactive=false
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
				wok_nginx_pusage;;

			-i|--interactive)
				interactive=true;;

			-p*|--password=*);;

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
		wok_perror "Invalid usage. See '${WOK_COMMAND} nginx --help'."
		wok_exit $EXIT_ERR_USR
	fi

	# Get the action
	array_shift args_remain action

	case "$action" in

		add)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} nginx --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			cmd=(wok_nginx_add "$domain" "$interactive")
			if ! ui_showProgress "Binding domain '${domain}' to 'nginx' module" "${cmd[@]}"; then
				return 1
			fi

			if [[ -n $report_log ]]; then
				wok_report_insl report_log "nginx: ~"
			fi;;

		list|ls)
			wok_nginx_list
			return $?;;

		remove|rm)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} nginx --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			if ! $force && ! ui_confirm "You are about to delete all files related to ${domain}. Continue?"; then
				echo "Aborted."
				return 0
			fi

			cmd=(wok_nginx_remove "$domain")
			ui_showProgress "Unbinding domain '${domain}' from 'nginx' module" "${cmd[@]}"
			return $?;;

		*)
			wok_perror "Invalid usage. See '${WOK_COMMAND} nginx --help'."
			wok_exit $EXIT_ERR_USR;;

	esac
}

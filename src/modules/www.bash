
#
# Copyright © 2013-2015 Max Ruman <rmx@guanako.be>
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

wok_www_describe()
{
	echo "The www module handles system users, directories, nginx and PHP"
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
	echo "        Usage: ~ [--interactive|-i] [--with-ssl] <domain>"
	echo
	echo "    remove      Remove a domain"
	echo
	echo "        Usage: ~ [--force|-f] <domain>"
	echo
	echo "    create-ssl  Create an SSL certificate request for the given domain;"
	echo "                This command can only be called with interactive mode"
	echo
	echo "        Usage: ~ --interactive|-i [--force|-f] <domain>"
	echo
	echo "    edit-nginx  Edit nginx virtual host configuration using ${EDITOR}"
	echo
	echo "        Usage: ~ <domain>"
	echo
	echo "    edit-php    Edit PHP FPM pool configuration using ${EDITOR}"
	echo
	echo "        Usage: ~ <domain>"
	echo
	echo "    su          Log-in as the specififed user"
	echo
	echo "        Usage: ~ <domain>"
	echo
}

wok_www_add()
{
	local domain="$1"
	local interactive="$2"
	local passwd="$3"

	local uid
	local uid_index
	local umask_prev
	local user_gid="$(wok_config_get wok_www user_gid)"
	local user_shell="$(wok_config_get wok_www user_shell)"
	local home_template="$(wok_config_get wok_www home_template)"
	local home_path_base="$(wok_config_get wok_www home_path_base)"
	local home_path
	local home_passwd_file="$(wok_config_get wok_www home_passwd_file)"
	local home_passwd_path
	local www_template="$(wok_config_get wok_www www_template)"
	local www_path_base="$(wok_config_get wok_www www_path_base)"
	local www_path
	local nginx_vhost_conf_template="$(wok_config_get wok_www nginx_vhost_conf_template)"
	local nginx_vhost_conf_dir="$(wok_config_get wok_www nginx_vhost_conf_dir)"
	local nginx_daemon_command_reload=$(wok_config_get wok_www nginx_daemon_command_reload)
	local nginx_vhost_conf_path
	local php_fpm_pool_template="$(wok_config_get wok_www php_fpm_pool_template)"
	local php_fpm_pool_dir="$(wok_config_get wok_www php_fpm_pool_dir)"
	local php_daemon_command_reload=$(wok_config_get wok_www php_daemon_command_reload)
	local php_fpm_pool_path

	if ! wok_repo_has "$domain"; then
		wok_perror "Domain '${domain}' is not managed by Wok."
		wok_exit $EXIT_ERR_USR
	fi

	if wok_www_has "$domain"; then
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
	if [[ ! -d "$home_path_base" || ! -w "$home_path_base" ]]; then
		wok_perror "Home base directory '${home_path_base}' does not exist or is not writable."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -d "$www_path_base" || ! -w "$www_path_base" ]]; then
		wok_perror "Www base directory '${www_path_base}' does not exist or is not writable."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -d "$nginx_vhost_conf_dir" || ! -w "$nginx_vhost_conf_dir" ]]; then
		wok_perror "Nginx vhost configuration directory '${nginx_vhost_conf_dir}' does not exist or is not writable."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -d "$php_fpm_pool_dir" || ! -w "$php_fpm_pool_dir" ]]; then
		wok_perror "PHP FPM pool directory '${php_fpm_pool_dir}' does not exist or is not writable."
		wok_exit $EXIT_ERR_SYS
	fi

	# Generate paths
	home_path="${home_path_base}/${uid}"
	home_passwd_path="${home_path}/${home_passwd_file}"
	www_path="${www_path_base}/${domain}"
	nginx_vhost_conf_path="${nginx_vhost_conf_dir}/${domain}.conf"
	php_fpm_pool_path="${php_fpm_pool_dir}/${uid}.conf"

	# Verify templates existence
	if [[ ! -e "$home_template" ]]; then
		wok_perror "Home template '${home_template}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -e "$www_template" ]]; then
		wok_perror "Www template '${www_template}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -e "$nginx_vhost_conf_template" ]]; then
		wok_perror "Nginx vhost configuration template '${nginx_vhost_conf_template}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -e "$php_fpm_pool_template" ]]; then
		wok_perror "PHP FPM pool template '${php_fpm_pool_template}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi

	# Verify paths availability
	if [[ -e $home_path ]]; then
		wok_perror "Home directory '${home_path}' already exists."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ -e $www_path ]]; then
		wok_perror "Www directory '${www_path}' already exists."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ -e $nginx_vhost_conf_path ]]; then
		wok_perror "Nginx vhost configuration file '${nginx_vhost_conf_path}' already exists."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ -e $php_fpm_pool_path ]]; then
		wok_perror "PHP FPM pool file '${php_fpm_pool_path}' already exists."
		wok_exit $EXIT_ERR_SYS
	fi

	# Create system user
	if ! useradd -g "$user_gid" -d "$home_path" -s "$user_shell" "$uid"; then
		wok_perror "Could not create system user '${uid}'."
		wok_exit $EXIT_ERR_SYS
	fi

	# Create www direcotry
	umask_prev="$(umask)"
	umask "$(wok_config_get wok_www www_umask)"
	if ! cp -r "$www_template" "$www_path"; then
		wok_perror "Could not create www directory '${www_path}'."
		wok_exit $EXIT_ERR_SYS
	fi
	chown -R "${uid}:${user_gid}" "$www_path"
	umask "$umask_prev"

	# Create home directory
	umask_prev="$(umask)"
	umask "$(wok_config_get wok_www home_umask)"
	if ! cp -r "$home_template" "$home_path"; then
		wok_perror "Could not create home directory '${home_path}'."
		wok_exit $EXIT_ERR_SYS
	fi
	ln -s "$www_path" "${home_path}/www"
	[[ -d "${home_path}/.ssh" ]] && chmod g=,o= "${home_path}/.ssh"
	echo "$passwd" > "$home_passwd_path"
	chmod 400 "$home_passwd_path"
	chown -R "${uid}:${user_gid}" "$home_path"
	umask "$umask_prev"

	# Configure Nginx
	cp "$nginx_vhost_conf_template" "$nginx_vhost_conf_path"
	sed -i "s/{domain}/${domain}/g" "$nginx_vhost_conf_path"
	sed -i "s/{uid}/${uid}/g" "$nginx_vhost_conf_path"

	# Configure PHP
	cp "$php_fpm_pool_template" "$php_fpm_pool_path"
	sed -i "s/{domain}/${domain}/g" "$php_fpm_pool_path"
	sed -i "s/{uid}/${uid}/g" "$php_fpm_pool_path"

	# Register...
	wok_repo_module_add "www" "$domain"
	wok_repo_module_index_add "www" "uid" "$uid"
	wok_repo_module_data_set "www" "$domain" "uid" "$uid"

	# Reload PHP and Nginx daemons
	$php_daemon_command_reload
	$nginx_daemon_command_reload
}

wok_www_has()
{
	local domain="$1"

	wok_repo_module_has www "$domain"
}

wok_www_list()
{
	wok_repo_module_list www | sort
}

wok_www_remove()
{
	local domain="$1"

	local uid
	local home_path
	local www_path
	local nginx_vhost_conf_dir="$(wok_config_get wok_www nginx_vhost_conf_dir)"

	if ! wok_www_has "$domain"; then
		wok_perror "Domain '${domain}' is not bound to 'www' module."
		wok_exit $EXIT_ERR_USR
	fi

	uid="$(wok_www_getUid "$domain")"
	home_path="$(wok_config_get wok_www home_path_base)/${uid}"
	www_path="$(wok_config_get wok_www www_path_base)/${domain}"
	local nginx_vhost_conf_path="$(wok_config_get wok_www nginx_vhost_conf_dir)/${domain}.conf"
	local nginx_daemon_command_reload=$(wok_config_get wok_www nginx_daemon_command_reload)
	local php_fpm_pool_path="$(wok_config_get wok_www php_fpm_pool_dir)/${uid}.conf"
	local php_daemon_command_reload=$(wok_config_get wok_www php_daemon_command_reload)

	if ! egrep -q "^${uid}:" /etc/passwd; then
		wok_perror "System user '${uid}' does not exist on this host."
		wok_exit $EXIT_ERR_SYS
	fi

	if [[ ! -d $home_path ]]; then
		wok_perror "Home directory '${home_path}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -d $www_path ]]; then
		wok_perror "WWW directory '${www_path}' does not exist."
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -f $nginx_vhost_conf_path || ! -w $nginx_vhost_conf_path ]]; then
		wok_perror "Nginx vhost configuration file '${nginx_vhost_conf_path}' does not exist or is not deletable (writable)"
		wok_exit $EXIT_ERR_SYS
	fi
	if [[ ! -f $php_fpm_pool_path || ! -w $php_fpm_pool_path ]]; then
		wok_perror "PHP FPM pool file '${php_fpm_pool_path}' does not exist or is not deletable (writable)"
		wok_exit $EXIT_ERR_SYS
	fi

	# Remove Nginx and PHP configuration files
	rm -f "$nginx_vhost_conf_path"
	rm -f "$php_fpm_pool_path"

	# Reload PHP and Nginx daemons
	$nginx_daemon_command_reload
	$php_daemon_command_reload

	# Remove system user
	if ! userdel -f "$uid"; then
		wok_perror "Error deleting system user '${uid}'"
		wok_exit $EXIT_ERR_SYS
	fi

	if [[ -d $home_path ]]; then
		rm -rf "$home_path"
	fi
	rm -rf "$www_path"

	# Unregister...
	wok_repo_module_remove "www" "$domain"
	wok_repo_module_index_remove "www" "uid" "$uid"
	wok_repo_module_data_remove "www" "$domain"
}

wok_www_getUid()
{
	local domain="$1"

	if ! wok_www_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'www' module."
		wok_exit $WOK_ERR_SYS
	fi

	wok_repo_module_data_get "www" "$domain" "uid"
}

wok_www_getGid()
{
	local domain="$1"

	if ! wok_www_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'www' module."
		wok_exit $WOK_ERR_SYS
	fi

	wok_config_get wok_www user_gid
}

wok_www_getWwwPath()
{
	local domain="$1"

	if ! wok_www_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'www' module."
		wok_exit $WOK_ERR_SYS
	fi

	echo "$(wok_config_get wok_www www_path_base)/${domain}"
}

wok_www_getHomePath()
{
	local domain="$1"

	if ! wok_www_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'www' module."
		wok_exit $WOK_ERR_SYS
	fi

	echo "$(wok_config_get wok_www home_path_base)/$(wok_www_getUid "$domain")"
}

wok_www_getModuleRcPath()
{
	local domain="$1"
	local module="$2" # Facultative

	if ! wok_www_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'www' module."
		wok_exit $WOK_ERR_SYS
	fi

	local home_path="$(wok_www_getHomePath "$domain")"
	local home_modules_rc_dir="$(wok_config_get wok_www home_modules_rc_dir)"
	local home_modules_rc_path="${home_path}/${home_modules_rc_dir}"

	if [[ -z $module ]]; then
		echo "$home_modules_rc_path"
	else
		echo "${home_modules_rc_path}/${module}.rc"
	fi
}

wok_www_getPassword()
{
	local domain="$1"

	if ! wok_www_has "$domain"; then
		wok_perror "Domain ${domain} is not managed by 'www' module."
		wok_exit $WOK_ERR_SYS
	fi

	local home_path="$(wok_www_getHomePath "$domain")"
	local home_passwd_file="$(wok_config_get wok_www home_passwd_file)"
	local home_passwd_path="${home_path}/${home_passwd_file}"

	if [[ ! -f $home_passwd_path ]]; then
		return 1
	fi

	cat "$home_passwd_path"
}

#
# Create an SSL certificate request (and a temporary self-signed one).
# It must be run in interactive mode!
#
# @param string domain The domain name
# @param bool   force  Force the replacement of the previous certificate
#
wok_www_createSsl()
{
	local domain="$1"
	local force="$2"

	local nginx_ssl_key_size="$(wok_config_get wok_www nginx_ssl_key_size)"
	local nginx_ssl_dir="$(wok_config_get wok_www nginx_ssl_dir)"
	local nginx_ssl_key_path="${nginx_ssl_dir}/${domain}.key"
	local nginx_ssl_csr_path="${nginx_ssl_dir}/${domain}.csr"
	local nginx_ssl_cer_path="${nginx_ssl_dir}/${domain}.cer"

	if ! wok_www_has "$domain"; then
		wok_perror "Domain '${domain}' is not bound to 'www' module."
		wok_exit $EXIT_ERR_USR
	fi

	# Check if a certificate something already exist
	if [[ \
		   -f $nginx_ssl_key_path \
		|| -f $nginx_ssl_csr_path \
		|| -f $nginx_ssl_cer_path \
	]]; then
		if ! $force && ! ui_confirm "A certificate file already exist. Replace?"; then
			echo "SSL certfificate signing request aborted."
			return
		fi

		if \
			   [[ -f $nginx_ssl_key_path && ! -w $nginx_ssl_key_path ]] \
			|| [[ -f $nginx_ssl_csr_path && ! -w $nginx_ssl_csr_path ]] \
			|| [[ -f $nginx_ssl_cer_path && ! -w $nginx_ssl_cer_path ]] \
		; then
			wok_perror "A certificate file already exist but is not deletable (writable)"
			wok_exit $EXIT_ERR_SYS
		fi
	fi

	# Create the private key
	openssl genrsa -out "$nginx_ssl_key_path" "$nginx_ssl_key_size"
	chmod 600 "$nginx_ssl_key_path"

	# Create the certificate signing request
	openssl req -new -key "$nginx_ssl_key_path" -out "$nginx_ssl_csr_path"
	chmod 600 "$nginx_ssl_csr_path"

	# Create a temporary self-signed certificate
	openssl x509 -req -in "$nginx_ssl_csr_path" -signkey "$nginx_ssl_key_path" -out "$nginx_ssl_cer_path"
	chmod 600 "$nginx_ssl_cer_path"

	echo "Certificate created successfully!"
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
	local with_ssl=false

	# Temp vars
	local arg
	local arg_value
	local args_remain=()
	local retval

	# Process arguments
	for arg in "$@"; do
		case "$arg" in

			-h|--help)
				wok_www_pusage
				wok_exit $EXIT_OK;;

			-i|--interactive)
				interactive=true;;

			-p*|--password=*)
				if ! passwd="$(arg_parseValue "$arg")"; then
					wok_perror "Invalid usage."
					wok_exit $EXIT_ERR_USR
				fi
				if ! [[ $passwd =~ $WOK_PASSWD_PATTERN ]]; then
					wok_perror "The password must match the following pattern: ${WOK_PASSWD_PATTERN}"
					wok_exit $EXIT_ERR_USR
				fi;;

			-f|--force)
				force=true;;

			--with-ssl)
				with_ssl=true;;

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

			if $with_ssl && ! $interactive; then
				wok_perror "Can't create an SSL certificate signing request in non-interactive mode"
				wok_exit $EXIT_ERR_USR
			fi

			cmd=(wok_www_add "$domain" "$interactive" "$passwd")
			if ! ui_showProgress "Binding domain '${domain}' to 'www' module" "${cmd[@]}"; then
				return 1
			fi

			if [[ -n $report_log ]]; then
				wok_report_insl report_log "www:"
				wok_report_insl report_log "    uid: %s" "$(wok_repo_module_data_get "www" "$domain" "uid")"
				if $with_ssl; then
					wok_report_insl report_log "    ssl: yes"
				fi
			fi

			if $with_ssl; then
				wok_www_createSsl  "$domain" "$force"
			fi;;

		list|ls)
			wok_www_list
			return $?;;

		remove|rm)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} www --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			if ! $force && ! ui_confirm "You are about to delete all files related to ${domain}. Continue?"; then
				echo "Aborted."
				return 0
			fi

			cmd=(wok_www_remove "$domain")
			ui_showProgress "Unbinding domain '${domain}' from 'www' module" "${cmd[@]}"
			return $?;;

		create-ssl)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} www --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			if ! $interactive; then
				wok_perror "Can't create an SSL certificate signing request in non-interactive mode"
				wok_exit $EXIT_ERR_USR
			fi

			wok_www_createSsl  "$domain" "$force";;

		edit-nginx)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} www --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			if ! wok_www_has "$domain"; then
				wok_perror "Domain '${domain}' is not bound to 'www' module."
				wok_exit $EXIT_ERR_USR
			fi

			local nginx_vhost_conf_dir="$(wok_config_get wok_www nginx_vhost_conf_dir)"
			local nginx_daemon_command_reload=$(wok_config_get wok_www nginx_daemon_command_reload)

			$EDITOR "${nginx_vhost_conf_dir}/${domain}.conf" -c "setf nginx"
			ui_showProgress "Reloading nginx" $nginx_daemon_command_reload;;

		edit-php)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} www --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			if ! wok_www_has "$domain"; then
				wok_perror "Domain '${domain}' is not bound to 'www' module."
				wok_exit $EXIT_ERR_USR
			fi

			local uid="$(wok_www_getUid "$domain")"
			local php_fpm_pool_dir="$(wok_config_get wok_www php_fpm_pool_dir)"
			local php_daemon_command_reload=$(wok_config_get wok_www php_daemon_command_reload)

			$EDITOR "${php_fpm_pool_dir}/${uid}.conf" -c "setf dosini"
			ui_showProgress "Reloading PHP" $php_daemon_command_reload;;

		su)
			if [[ ${#args_remain[@]} -ne 1 ]]; then
				wok_perror "Invalid usage. See '${WOK_COMMAND} www --help'."
				wok_exit $EXIT_ERR_USR
			fi
			array_shift args_remain domain || wok_exit $EXIT_ERR_SYS

			if ! wok_www_has "$domain"; then
				wok_perror "Domain '${domain}' is not bound to 'www' module."
				wok_exit $EXIT_ERR_USR
			fi

			local uid="$(wok_www_getUid "$domain")"
			su - "$uid";;

		*)
			wok_perror "Invalid usage. See '${WOK_COMMAND} www --help'."
			wok_exit $EXIT_ERR_USR;;

	esac
}

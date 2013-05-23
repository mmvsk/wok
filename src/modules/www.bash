
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
	echo "                 [--report-log=<file>] <domain>"
	echo
	echo "    remove      Remove a domain"
	echo
	echo "        Usage: ~ [--force|-f] <domain>"
	echo
}

wok_www_add()
{
	echo
}

wok_www_list()
{
	echo
}

wok_www_remove()
{
	echo
}

wok_www_handle()
{
	# Argument vars
	local domain=""
	local interactive=false
	local passwd=""
	local report_log=""

	# Temp vars
	local arg
	local arg_value
	local args_remain=()

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

	# Only one additional argument is required: the domain name
	if [[ ${#args_remain[@]} -ne 1 ]]; then
		wok_perror "Invalid usage. See '${WOK_COMMAND} www --help'."
		wok_exit $EXIT_ERR_USR
	fi

	# Domain name processing
	domain="${args_remain[0]}"
}

_____()
{
# Processing
	force=
	action=
#domain=
	argv=
	while [ -n "$1" ]; do
		arg=$1;shift
		case $arg in
			-f|--force) force=1;;
			*)
				if test -z "$action"; then action="$arg"
				#elif test -z "$domain"; then domain="$arg"
				else argv="$argv $arg"
				fi
				;;
		esac
	done
	set -- $argv # Restitute the rest...

# Validation
	test -z "$action" && usage
	test $action != 'add' \
	&& test $action != 'rm' \
	&& test $action != 'uid' \
	&& test $action != 'ls' \
		&& usage "Invalid action."

# Add, rm, user validation
	if [ $action != 'ls' ]; then
		domain="$1";shift
		test -z "$domain" && usage "Give a domain (e.g. example.org)."
		test ! $(preg_match ':^[a-z0-9\-.]{1,255}$:' $domain) \
			&& echo "Invalid domain name" \
			&& exit 1
	fi

	if [ $action = 'ls' ]; then
		pattern="$1";shift
		test -z "$pattern" && pattern='*'
	fi

# Run
#=====

	case $action in
		ls)
			silent cd $repo
			find . -maxdepth 1 -type f -name "$pattern" \
				| sed -r 's/^.{2}//' \
				| sort
			silent cd -
			;;
		add)
			test -e $index_domain/$domain \
				&& echo "This domain already exists" \
				&& exit 1
			uid="$(slugify 32 $domain $index_uid - www-)"
			test -z "$uid" && echo "Could not create user slug" && exit 1
			touch $repo/$domain
			ln -s "../../$domain" $index_domain/$domain
			ln -s "../../$domain" $index_uid/$uid
			echo "_domain=$domain" >> $repo/$domain
			echo "_uid=$uid" >> $repo/$domain
			echo -n "Creating directory: $wok_www_path/$domain... "
				mkdir -p $wok_www_path/$domain
				echo "done"
			echo -n "Creating log directory: $wok_www_log_path/$domain... "
				mkdir -p $wok_www_log_path/$domain
				echo "done"
			echo -n "Creating system user: $uid... "
				useradd \
					-g $wok_www_uid_group \
					-s $wok_www_uid_shell \
					-M -d $wok_www_path/$domain \
					$uid
				chown -R $uid:$wok_www_uid_group $wok_www_path/$domain
				echo "done"
			echo -n "Creating default structure... "
				touch $wok_www_path/$domain/.zshrc
				mkdir $wok_www_path/$domain/public
				cat $wok_www_placeholder | sed "s/{site}/$domain/g" > $wok_www_path/$domain/public/index.php
				mkdir $wok_www_path/$domain/.ssh
				chmod -R 700 $wok_www_path/$domain/.ssh
				touch $wok_www_path/$domain/.ssh/authorized_keys
				cat $wok_www_key_path/* >> $wok_www_path/$domain/.ssh/authorized_keys
				chmod 600 $wok_www_path/$domain/.ssh/authorized_keys
				chown -R $uid:$wok_www_uid_group $wok_www_path/$domain
				echo "done"
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

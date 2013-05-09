#!/bin/bash

repo=$wok_repo/pgsql
index_domain=$repo/.index/domain
index_user=$repo/.index/user
index_db=$repo/.index/db

test ! -d $repo \
|| test ! -d $index_domain \
|| test ! -d $index_user \
|| test ! -d $index_db \
	&& echo "Invalid repository" \
	&& exit 1

# Parameters
#============

usage() {
	test -n "$1" && echo -e "$1\n"
	echo "Usage: wok pgsql <action>"
	echo
	echo "    add [options] <domain>  Create the domain"
	echo "        -p, --password <password>"
	echo "    rm [options] <domain>   Remove the domain"
	echo "        -f, --force         ... without confirmation"
	echo "    ls [pattern]            List domains (by pattern if specified)"
	echo "    createdb <domain> <db>  Create additional database [NOT IMPLEMENTED YET]"
	echo "    dropdb <domain> <db>    Create additional database [NOT IMPLEMENTED YET]"
	echo
	exit 1
}

error() {
	echo $1
	exit 1
}

# Processing
action=
password=
force=
argv=
while [ -n "$1" ]; do
	arg="$1";shift
	case "$arg" in
		-p|--password) password="$1";shift;;
		-f|--force) force=1;;
		*)
			if test -z "$action"; then action="$arg"
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
			&& error "This domain has already an user and a database"
		test -z "$($wok_path/wok-www ls $domain)" \
			&& error "This domain does not exist"
		uid="$($wok_path/wok-www uid $domain)"
		test -z "$password" && getpasswd password
		test "$(preg_match ':\\W:' "$password")" && error "Invalid password."
		user="$(slugify 63 $domain $index_user _ www_)"
		db="$(slugify 63 $domain $index_db _ www_)"
		echo -n "Creating PostgreSQL user and database $user... "
			cmd="
				create user \"$user\" with encrypted password '$password';
				create database \"$db\" owner \"$user\";
			"
			echo "$cmd" | $(cd /tmp; silent sudo -u postgres psql)
			echo "done"
			echo "export PGHOST=localhost" >> $wok_www_path/$domain/.zshrc
			echo "export PGUSER='${user}'" >> $wok_www_path/$domain/.zshrc
			echo "localhost:*:*:${user}:${password}" >> $wok_www_path/$domain/.pgpass
			chmod 400 $wok_www_path/$domain/.pgpass
			chown $uid:$wok_www_uid_group $wok_www_path/$domain/.pgpass
		touch $repo/$domain
		ln -s "../../$domain" $index_domain/$domain
		ln -s "../../$domain" $index_user/$user
		ln -s "../../$domain" $index_db/$db
		echo "_domain=$domain" >> $repo/$domain
		echo "_user=$user" >> $repo/$domain
		echo "_db=$db" >> $repo/$domain
		;;
	rm)
		test ! -e $index_domain/$domain && exit 1
		if test ! $force; then
			confirm "Remove PostgreSQL user and database?" || exit 0
		fi
		source $repo/$domain
		echo -n "Removing PostgreSQL database and user... "
			cmd="
				drop database if exists \"$_db\";
				drop user if exists \"$_user\";
			"
			echo "$cmd" | $(cd /tmp; silent sudo -u postgres psql)
			echo "done"
		rm $index_domain/$_domain
		rm $index_user/$_user
		rm $index_db/$_db
		rm $repo/$domain
		;;
esac

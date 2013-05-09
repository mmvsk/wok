#!/bin/bash

repo=$wok_repo/mail
index_domain=$repo/.index/domain
index_account=$repo/.index/account
index_alias=$repo/.index/alias

test ! -d $repo \
|| test ! -d $index_domain \
|| test ! -d $index_account \
|| test ! -d $index_alias \
	&& echo "Invalid repository" \
	&& exit 1

# Parameters
#============

usage() {
	test -n "$1" && echo -e "$1\n"
	echo "Usage: wok mail-alias <domain> <action>"
	echo
	echo "    add <src> <dest@host>  Create an alias for the domain"
	echo "    rm <src>               Remove an alias of the domain"
	echo "    ls [pattern=*]         List aliases of the domain"
	echo
	exit 1
}

error() {
	echo $1
	exit 1
}

# Processing
domain=
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
			if test -z "$domain"; then domain="$arg"
			elif test -z "$action"; then action="$arg"
			else argv="$argv $arg"
			fi
			;;
	esac
done
set -- $argv # Restitute the rest...

# Validation
test -z "$domain" && usage
test -z "$action" && usage
test $action != 'add' \
&& test $action != 'rm' \
&& test $action != 'ls' \
	&& usage "Invalid action."
test ! $(preg_match ':^[a-z0-9\-.]{1,255}$:' $domain) \
	&& error "Invalid domain name."
test ! -e "$repo/$domain" \
	&& error "This domain does not exist."

if [ $action = 'add' ]; then
	alias_src="$1"
	alias_dest="$2"
	shift 2
	test -z "$alias_src" && usage "Give the source virtual user"
	test -z "$alias_dest" && usage "Give the destination address"
	test ! $(preg_match ':^[a-z0-9\-.]{1,255}$:' $alias_src) && error "Invalid source alias"
	test ! $(preg_match ':^([a-z0-9.-]{1,64}@[a-z0-9.-]{1,64},?)+$:i' $alias_dest) && error "Invalid destination address"
fi

if [ $action = 'rm' ]; then
	alias_src="$1";shift
	test -z "$alias_src" && usage "Give the source virtual user"
fi

if [ $action = 'ls' ]; then
	pattern="$1";shift
	test -z "$pattern" && pattern='*'
fi

# Run
#=====

case $action in
	ls)
		if test -e $index_alias/$domain; then
			silent cd $index_alias/$domain
			for f in $(find . -maxdepth 1 -type f -name "$pattern" | sed -r 's/^.{2}//' | sort); do
				echo -e "$f -> $(cat $f)"
			done
			silent cd -
		fi
		;;
	add)
		test -z "$($wok_path/wok-mail ls $domain)" \
			&& error "This domain has no mail registration"
		test ! -e $index_alias/$domain && mkdir $index_alias/$domain
		test -e $index_alias/$domain/$alias_src \
			&& error "This alias exists"
		echo -n "Creating alias $alias_src@$domain -> $alias_dest... "
			cmd="
				insert into public.virtual_alias (domain_id, source, destination)
				values (
					(select id from public.virtual_domain where name = '$domain'),
					'$alias_src@$domain',
					'$alias_dest'
				);
			"
			echo "$cmd" | $(cd /tmp; silent sudo -u postgres psql $wok_mail_db)
			echo "done"
		echo "$alias_dest" > $index_alias/$domain/$alias_src
		;;
	rm)
		test ! -e $index_alias/$domain/$alias_src && exit 1
		#source $index_alias/$domain
		echo -n "Removing alias $alias_src... "
			cmd="
				delete from public.virtual_alias where source = '$alias_src@$domain';
			"
			echo "$cmd" | $(cd /tmp; silent sudo -u postgres psql $wok_mail_db)
			echo "done"
		rm $index_alias/$domain/$alias_src
		;;
esac

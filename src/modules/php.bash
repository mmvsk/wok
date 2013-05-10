#!/bin/bash

repo=$wok_repo/apache
index_domain=$repo/.index/domain

test ! -d $repo \
|| test ! -d $index_domain \
	&& echo "Invalid repository" \
	&& exit 1

# Parameters
#============

usage() {
	test -n "$1" && echo -e "$1\n"
	echo "Usage: wok apache <action>"
	echo
	echo "    add <domain>           Create the domain"
	echo "    rm <domain>            Remove the domain"
	echo "    ls [pattern]           List domains (by pattern if specified)"
	echo
	exit 1
}

error() {
	echo $1
	exit 1
}

# Processing
action=
#domain=
argv=
while [ -n "$1" ]; do
	arg=$1;shift
	case $arg in
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
			&& error "This domain is already registeted"
		test -z "$($wok_path/wok-www ls $domain)" \
			&& error "This domain does not exist"
		uid="$($wok_path/wok-www uid $domain)"
		echo -n "Registering domain $domain... "
			cat $wok_apache_template \
				| sed "s/{domain}/$domain/g" \
				| sed "s/{uid}/$uid/g" \
				> $wok_apache_vhosts/$domain.conf
			echo "done"
		echo $(service $wok_apache_service reload)
		touch $repo/$domain
		ln -s "../../$domain" $index_domain/$domain
		echo "_domain=$domain" >> $repo/$domain
		;;
	rm)
		test ! -e $index_domain/$domain && exit 1
		echo -n "Unregistering domain $domain... "
			rm $wok_apache_vhosts/$domain.conf
			echo "done"
		echo "$(service $wok_apache_service reload)"
		source $repo/$domain
		rm $index_domain/$_domain
		rm $repo/$domain
		;;
esac

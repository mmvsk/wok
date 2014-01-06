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
	echo "Usage: wok mail-account <domain> <action>"
	echo
	echo "    add <name> [options]  Create an account for the domain"
	echo "        -p, --password <password>"
	echo "    rm <name>             Remove an account of the domain"
	echo "    ls [pattern=*]        List accounts of the domain"
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
	account="$1";shift
	test -z "$account" && usage "Give the account name"
	test ! $(preg_match ':^[a-z0-9\-.]{1,255}$:' $account) && error "Invalid account name"
fi

if [ $action = 'rm' ]; then
	account="$1";shift
	test -z "$account" && usage "Give the account"
fi

if [ $action = 'ls' ]; then
	pattern="$1";shift
	test -z "$pattern" && pattern='*'
fi

# Run
#=====

case $action in
	ls)
		if test -e $index_account/$domain; then
			silent cd $index_account/$domain
			for f in $(find . -maxdepth 1 -type f -name "$pattern" | sed -r 's/^.{2}//' | sort); do
				echo -e "$f"
			done
			silent cd -
		fi
		;;
	add)
		test -z "$($wok_path/wok-mail ls $domain)" \
			&& error "This domain has no mail registration"
		test ! -e $index_account/$domain && mkdir $index_account/$domain
		test -e $index_account/$domain/$account \
			&& error "This account exists"
		test -z "$password" && getpasswd password
		test "$(preg_match ':\\W:' "$password")" && error "Invalid password."
		echo -n "Creating account $account@$domain... "
			cmd="
				insert into public.virtual_user (domain_id, email, password)
				values (
					(select id from public.virtual_domain where name = '$domain'),
					'$account@$domain',
					md5('$password')
				);
			"
			echo "$cmd" | $(cd /tmp; silent sudo -u postgres psql $wok_mail_db)
			echo "done"
		touch $index_account/$domain/$account
		;;
	rm)
		test ! -e $index_account/$domain/$account && exit 1
		#source $index_account/$domain
		echo -n "Removing account $account@$domain... "
			cmd="
				delete from public.virtual_user where email = '$account@$domain';
			"
			echo "$cmd" | $(cd /tmp; silent sudo -u postgres psql $wok_mail_db)
			echo "done"
		rm $index_account/$domain/$account
		;;
esac

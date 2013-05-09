#!/bin/bash

# Parameters
#============

usage() {
	test -n "$1" && echo -e "$1\n"
	echo "Usage: wok add [options] <domain>"
	echo
	echo "    -p, --password <password>  set the global password (used in every submodule)"
	echo
	exit 1
}

# Processing
domain=
force=
password=
argv=
while [ -n "$1" ]; do
	arg=$1;shift
	case $arg in
		-p|--password) password=$1;shift;;
		-f|--force) force=1;;
		*)
			if test -z "$domain"; then domain="$arg"
			else argv="$argv $arg"
			fi
			;;
	esac
done

# Validation
test -z "$domain" && usage "Give a domain (e.g. example.org)."

# Run
#=====

if [ -z "$password" ] && confirm "Generate global password?"; then
	password=$(makepasswd --chars=8)
fi

args=
test -n "$password" && args="$args --password $password"
test "$force" && args="$args --force"

$wok_path/wok-www add $domain $args
$wok_path/wok-php add $domain $args
$wok_path/wok-nginx add $domain $args
confirm "Create SSL self-signed certificate/key?" && $wok_path/wok-ssl add $domain $args
#confirm "Create FTP access?" && $wok_path/wok-ftp add $domain $args
confirm "Create PostgreSQL user and database?" && $wok_path/wok-pgsql add $domain $args
confirm "Create MySQL user and database?" && $wok_path/wok-mysql add $domain $args
confirm "Create MongoDB user and database?" && $wok_path/wok-mongo add $domain $args
#confirm "Create a mail domain?" && $wok_path/wok-mail add $domain $args

report=$(mktemp)
echo    "Wok recipe: $domain" >> $report
echo -n "============" >> $report
perl -e "print '=' x ${#domain}" >> $report; echo >> $report
if test -e $wok_repo/www/$domain; then
	echo -e "\n[www]\n" >> $report
	source $wok_repo/www/$domain
	echo "domain = $_domain" >> $report
	echo "uid    = $_uid" >> $report
fi
if test -e $wok_repo/ftp/$domain; then
	echo -e "\n[ftp]\n" >> $report
	source $wok_repo/ftp/$domain
	echo "type = FTPS (explicit)" >> $report
	echo "host = $domain" >> $report
	echo "user = $_user" >> $report
	echo "pass = $password" >> $report
fi
if test -e $wok_repo/pgsql/$domain; then
	echo -e "\n[pgsql]\n" >> $report
	source $wok_repo/pgsql/$domain
	echo "user = $_user" >> $report
	echo "pass = $password" >> $report
	echo "db[] = $_db" >> $report
fi
if test -e $wok_repo/mysql/$domain; then
	echo -e "\n[mysql]\n" >> $report
	source $wok_repo/mysql/$domain
	echo "user = $_user" >> $report
	echo "pass = $password" >> $report
	echo "db[] = $_db" >> $report
fi
if test -e $wok_repo/mongo/$domain; then
	echo -e "\n[mongodb]\n" >> $report
	source $wok_repo/mongo/$domain
	echo "user = $_user" >> $report
	echo "pass = $password" >> $report
	echo "db[] = $_db" >> $report
fi
if test -e $wok_repo/mail/$domain; then
	echo -e "\n[mail]\n" >> $report
	source $wok_repo/mail/$domain
	echo "smtp: smtps (ssl), password auth, port 465" >> $report
	echo "imap: imaps (ssl), password auth, port 993" >> $report
fi

if confirm "Send report by e-mail?"; then
	read -ep "E-mail address (separate by coma): " mail_rcpt
	mailx -s "Wok recipe: $domain" -r $wok_add_mail_sender "$mail_rcpt" < $report
fi

rm $report

echo
